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

#include "backgroundpreviewwork.h"
#include <QtTest>
#include <future>
#include <chrono>
using namespace std::chrono_literals;
class TestBackgroundPreviewWork : public QObject {
    Q_OBJECT
private slots:
    void playbackBlocksThenResumes() {
        BackgroundPreviewWork gate;
        gate.setPlaying(true);
        auto result = std::async(std::launch::async, [&]() { return gate.waitUntilIdle(); });
        const bool blocked = result.wait_for(50ms) == std::future_status::timeout;
        gate.setPlaying(false);
        QVERIFY(blocked);
        QCOMPARE(result.wait_for(1s), std::future_status::ready);
        QVERIFY(result.get());
    }
    void shutdownReleasesPausedWorker() {
        BackgroundPreviewWork gate;
        gate.setPlaying(true);
        auto result = std::async(std::launch::async, [&]() { return gate.waitUntilIdle(); });
        gate.stop();
        QCOMPARE(result.wait_for(1s), std::future_status::ready);
        QVERIFY(!result.get());
        gate.setPlaying(false);
        QVERIFY(!gate.waitUntilIdle());
    }
};
QTEST_GUILESS_MAIN(TestBackgroundPreviewWork)
#include "test_background_preview_work.moc"
