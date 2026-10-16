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

#include "cutitfonts.h"
#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QNetworkReply>
#include <QRegularExpression>
#include <QSaveFile>
#include <QUrlQuery>
#ifdef Q_OS_WIN
#include <qt_windows.h>
#endif

static QList<CutItFonts *> fontInstances;

CutItFonts::CutItFonts(const QString &cache, const QString &bundled, QObject *parent)
    : QObject(parent)
    , m_cache(cache)
{
    fontInstances.append(this);
    for (const auto &folder : {bundled, cache}) {
        if (folder.isEmpty())
            continue;
        const QDir dir(folder);
        for (const auto &name : dir.entryList({"*.ttf"}, QDir::Files))
            load(dir.filePath(name));
    }
}

CutItFonts::~CutItFonts()
{
    release();
    fontInstances.removeAll(this);
}

void CutItFonts::releaseAll()
{
    for (auto *fonts : fontInstances)
        fonts->release();
}

void CutItFonts::release()
{
    if (qGuiApp) {
        for (const auto id : m_fontIds)
            QFontDatabase::removeApplicationFont(id);
    }
    m_fontIds.clear();
#ifdef Q_OS_WIN
    for (const auto &path : m_registeredPaths)
        RemoveFontResourceExW(reinterpret_cast<LPCWSTR>(QDir::toNativeSeparators(path).utf16()),
                              0,
                              nullptr);
#endif
    m_registeredPaths.clear();
}

QStringList CutItFonts::families() const
{
    return QFontDatabase::families();
}
QStringList CutItFonts::googleFamilies() const
{
    return {"Lato", "Noto Sans", "Bebas Neue", "Roboto", "Open Sans", "Oswald", "Lora", "Pacifico"};
}

bool CutItFonts::load(const QString &path)
{
    QString loadedPath = path;
#ifdef Q_OS_WIN
    // GDI can keep file-backed fonts locked for the session. Register immutable
    // cache copies, never files in the installation directory being updated.
    QFile source(path);
    if (!source.open(QIODevice::ReadOnly))
        return false;
    const auto bytes = source.readAll();
    const auto folder = QDir(m_cache).filePath("registered");
    if (!QDir().mkpath(folder))
        return false;
    loadedPath = QDir(folder).filePath(
        QString::fromLatin1(QCryptographicHash::hash(bytes, QCryptographicHash::Sha256).toHex())
        + ".ttf");
    if (!QFile::exists(loadedPath)) {
        QSaveFile cached(loadedPath);
        if (!cached.open(QIODevice::WriteOnly) || cached.write(bytes) != bytes.size()
            || !cached.commit())
            return false;
    }
    if (m_registeredPaths.contains(loadedPath))
        return true;
    // Session-visible registration also makes the font available to the separate
    // MLT export process. No registry entry or system font directory is changed.
    if (!AddFontResourceExW(reinterpret_cast<LPCWSTR>(QDir::toNativeSeparators(loadedPath).utf16()),
                            0,
                            nullptr))
        return false;
    m_registeredPaths.append(loadedPath);
#endif
    const int id = QFontDatabase::addApplicationFont(loadedPath);
    if (id >= 0)
        m_fontIds.append(id);
#ifdef Q_OS_WIN
    else {
        RemoveFontResourceExW(reinterpret_cast<LPCWSTR>(
                                  QDir::toNativeSeparators(loadedPath).utf16()),
                              0,
                              nullptr);
        m_registeredPaths.removeAll(loadedPath);
    }
#endif
    return id >= 0;
}

void CutItFonts::finish(const QString &message)
{
    m_busy = false;
    m_status = message;
    emit statusChanged();
}

void CutItFonts::request(const QUrl &url, std::function<void(QByteArray)> done)
{
    QNetworkRequest request(url);
    request.setTransferTimeout(20000);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::ManualRedirectPolicy);
    // The CSS API serves complete desktop-compatible TrueType files to this UA.
    request.setRawHeader("User-Agent", "Cut-it/0.1");
    auto reply = m_network.get(request);
    connect(reply, &QNetworkReply::downloadProgress, reply, [reply](qint64 bytes, qint64 total) {
        if (bytes > 16 * 1024 * 1024 || total > 16 * 1024 * 1024)
            reply->abort();
    });
    connect(reply, &QNetworkReply::finished, this, [this, reply, done]() {
        const auto bytes = reply->readAll();
        const bool ok = reply->error() == QNetworkReply::NoError
                        && reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt()
                               == 200;
        reply->deleteLater();
        if (!ok || bytes.isEmpty() || bytes.size() > 16 * 1024 * 1024) {
            finish(tr("Download failed. Your installed fonts still work offline."));
            return;
        }
        done(bytes);
    });
}

void CutItFonts::download(const QString &family)
{
    if (m_busy || !googleFamilies().contains(family))
        return;
    if (families().contains(family)) {
        finish(tr("%1 is ready. Choose it in Font.").arg(family));
        return;
    }
    m_busy = true;
    m_status = tr("Downloading %1…").arg(family);
    emit statusChanged();
    QUrl url("https://fonts.googleapis.com/css");
    QUrlQuery query;
    query.addQueryItem("family", family + ":400");
    query.addQueryItem("subset", "latin,cyrillic");
    url.setQuery(query);
    request(url, [this, family](const QByteArray &css) {
        const QRegularExpression re(QStringLiteral("https://fonts\\.gstatic\\.com/[^)\\s]+\\.ttf"));
        const auto match = re.match(QString::fromUtf8(css));
        if (!match.hasMatch()) {
            finish(tr("No desktop font was returned. Try another family."));
            return;
        }
        request(QUrl(match.captured()), [this, family](const QByteArray &font) {
            QString slug = family.toLower();
            slug.remove(' ');
            // Preserve the font's own copyright and license beside the cached file.
            request(QUrl("https://raw.githubusercontent.com/google/fonts/main/ofl/" + slug
                         + "/OFL.txt"),
                    [this, family, slug, font](const QByteArray &license) {
                        if (!QDir().mkpath(m_cache)) {
                            finish(tr("Could not create the font cache."));
                            return;
                        }
                        const QString path = QDir(m_cache).filePath(slug + ".ttf");
                        QSaveFile licenseFile(QDir(m_cache).filePath(slug + "-OFL.txt"));
                        QSaveFile fontFile(path);
                        if (!licenseFile.open(QIODevice::WriteOnly)
                            || licenseFile.write(license) != license.size() || !licenseFile.commit()
                            || !fontFile.open(QIODevice::WriteOnly)
                            || fontFile.write(font) != font.size() || !fontFile.commit()
                            || !load(path)) {
                            finish(tr("Could not load this font. Try another family."));
                            return;
                        }
                        emit familiesChanged();
                        finish(tr("%1 is ready. Choose it in Font.").arg(family));
                    });
        });
    });
}
