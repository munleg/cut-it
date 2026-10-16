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

#ifndef BACKGROUNDPREVIEWWORK_H
#define BACKGROUNDPREVIEWWORK_H
#include <QMutex>
#include <QMutexLocker>
#include <QWaitCondition>

// Only background workers wait here. Playback and the UI never wait for them.
class BackgroundPreviewWork
{
public:
    static BackgroundPreviewWork &instance()
    {
        static BackgroundPreviewWork gate;
        return gate;
    }
    void setPlaying(bool playing)
    {
        QMutexLocker lock(&m_mutex);
        m_playing = playing;
        if (!playing)
            m_ready.wakeAll();
    }
    bool waitUntilIdle()
    {
        QMutexLocker lock(&m_mutex);
        while (m_playing && !m_stopping)
            m_ready.wait(&m_mutex);
        return !m_stopping;
    }
    void stop()
    {
        QMutexLocker lock(&m_mutex);
        m_stopping = true;
        m_ready.wakeAll();
    }
private:
    QMutex m_mutex;
    QWaitCondition m_ready;
    bool m_playing = false;
    bool m_stopping = false;
};
#endif
