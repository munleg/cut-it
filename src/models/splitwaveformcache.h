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

#ifndef SHOTCUT_SPLITWAVEFORMCACHE_H
#define SHOTCUT_SPLITWAVEFORMCACHE_H

#include "shotcut_mlt_properties.h"
#include <Mlt.h>
#include <QByteArray>

// Split halves reference the same source audio. Reuse only a complete cache;
// partial waveforms must stay subscribed to the background generation task.
inline bool copySplitWaveform(Mlt::Producer &source, Mlt::Producer &destination)
{
    source.lock();
    auto levels = static_cast<QByteArray *>(source.get_data(kAudioLevelsProperty));
    QByteArray *copy = nullptr;
    if (levels && source.get_length() > 0
        && levels->size() >= qint64(source.get_length()) * 2)
        copy = new QByteArray(*levels);
    source.unlock();
    if (!copy)
        return false;
    destination.set(kAudioLevelsProperty, copy, 0,
                    [](void *data) { delete static_cast<QByteArray *>(data); });
    return true;
}

#endif
