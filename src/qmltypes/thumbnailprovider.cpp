/*
 * Copyright (c) 2013-2026 Meltytech, LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "thumbnailprovider.h"
#include "backgroundpreviewwork.h"

#include "Logger.h"
#include "database.h"
#include "mltcontroller.h"
#include "models/playlistmodel.h"
#include "settings.h"
#include "util.h"

#include <QCryptographicHash>
#include <QQuickImageProvider>
#include <atomic>

static std::atomic_bool stoppingThumbnails{false};

void ThumbnailProvider::stopRequests()
{
    stoppingThumbnails.store(true);
}

ThumbnailProvider::ThumbnailProvider()
    : QQuickImageProvider(QQmlImageProviderBase::Image,
                          QQmlImageProviderBase::ForceAsynchronousImageLoading)
    , m_profile("atsc_720p_60")
{}

QImage ThumbnailProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    QMutexLocker requestLock(&m_requestMutex);
    QImage result;
    if (stoppingThumbnails.load()) {
        if (size)
            *size = QSize();
        return result;
    }

    // id is [hash]/mlt_service/resource#frameNumber[!]
    // optional trailing '!' means to force update
    int index = id.lastIndexOf('#');

    if (index != -1) {
        QString myId = id;
        bool force = id.endsWith('!');
        if (force)
            myId = id.left(id.size() - 1);
        QString hash = myId.section('/', 0, 0);
        QString service = myId.section('/', 1, 1);
        QString resource = myId.section('/', 2);
        int frameNumber = myId.mid(index + 1).toInt();
        Mlt::Properties properties;

        // Scale the frameNumber to ThumbnailProvider profile's fps.
        frameNumber = qRound(frameNumber / MLT.profile().fps() * m_profile.fps());

        resource = resource.left(resource.lastIndexOf('#'));
        resource = Util::removeQueryString(resource);
        properties.set("_profile", m_profile.get_profile(), 0);

        QString key = cacheKey(properties, service, resource, hash, frameNumber);
        result = DB.getThumbnail(key);
        if (!stoppingThumbnails.load() && (force || result.isNull())) {
            if (service == "avformat-novalidate")
                service = "avformat";
            else if (service.startsWith("xml"))
                service = "xml-nogl";
            // Cache hits remain available during playback. Only new decoding waits.
            if (!BackgroundPreviewWork::instance().waitUntilIdle())
                return QImage();
            const QString decoderKey = service + QLatin1Char('\n') + resource
                                       + QLatin1Char('\n') + hash;
            const bool reusable = service.startsWith("avformat");
            if (!reusable || force || !m_decoder || m_decoderKey != decoderKey) {
                m_decoder.reset();
                m_decoderKey = decoderKey;
                if (service == "count") {
                    m_decoder.reset(new Mlt::Producer(m_profile, service.toUtf8().constData(), "loader-nogl"));
                } else if (!Settings.playerGPU() || (service != "xml-nogl" && service != "consumer")) {
                    m_decoder.reset(new Mlt::Producer(m_profile, service.toUtf8().constData(), resource.toUtf8().constData()));
                }
                if (m_decoder && m_decoder->is_valid()) {
                    m_decoder->set("audio_index", -1);
                    LOG_DEBUG() << "Cut-it thumbnail decoder opened";
                }
            }
            if (m_decoder && m_decoder->is_valid() && !stoppingThumbnails.load()) {
                result = makeThumbnail(*m_decoder, frameNumber, requestedSize);
                if (!stoppingThumbnails.load())
                    DB.putThumbnail(key, result);
            }
            if (!reusable)
                m_decoder.reset();
        }
    }
    if (result.isNull()) {
        result = QImage(1, 1, QImage::Format_Alpha8);
        result.fill(0);
    }
    if (size)
        *size = result.size();
    return result;
}

QString ThumbnailProvider::cacheKey(Mlt::Properties &properties,
                                    const QString &service,
                                    const QString &resource,
                                    const QString &hash,
                                    int frameNumber)
{
    QString time = properties.frames_to_time(frameNumber, mlt_time_clock);
    // Reduce the precision to centiseconds to increase chance for cache hit
    // without much loss of accuracy.
    time = time.left(time.size() - 1);
    QString key;
    if (hash.isEmpty()) {
        key = QStringLiteral("%1 %2 %3").arg(service).arg(resource).arg(time);
        QCryptographicHash hash(QCryptographicHash::Sha1);
        hash.addData(key.toUtf8());
        key = hash.result().toHex();
    } else {
        key = QStringLiteral("%1 %2").arg(hash).arg(time);
    }
    return key;
}

QImage ThumbnailProvider::makeThumbnail(Mlt::Producer &producer,
                                        int frameNumber,
                                        const QSize &requestedSize)
{
    Mlt::Filter scaler(m_profile, "swscale");
    Mlt::Filter padder(m_profile, "resize");
    Mlt::Filter converter(m_profile, "avcolor_space");
    int height = PlaylistModel::THUMBNAIL_HEIGHT * 2;
    int width = PlaylistModel::THUMBNAIL_WIDTH * 2;

    if (!requestedSize.isEmpty()) {
        width = requestedSize.width();
        height = requestedSize.height();
    }

    if (!producer.get_int("_cutit:thumbnailFilters")) {
        producer.attach(scaler);
        producer.attach(padder);
        producer.attach(converter);
        producer.set("_cutit:thumbnailFilters", 1);
    }
    return MLT.image(producer, frameNumber, width, height);
}
