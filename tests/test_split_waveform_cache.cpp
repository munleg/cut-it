/*
 * Copyright (c) 2026 Meltytech, LLC
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

#include "models/splitwaveformcache.h"
#include <QtTest>

class TestSplitWaveformCache : public QObject
{
    Q_OBJECT
private slots:
    void reuseAndOwnership()
    {
        Mlt::Factory::init();
        Mlt::Profile profile;
        Mlt::Producer source(profile, "color", "black");
        Mlt::Producer destination(profile, "color", "black");
        QVERIFY(source.is_valid());
        QVERIFY(destination.is_valid());
        source.set("length", 100);
        source.set_in_and_out(0, 99);
        QVERIFY(!copySplitWaveform(source, destination));
        auto setLevels = [&](int count) {
            source.set(kAudioLevelsProperty, new QByteArray(count, 'a'), 0,
                       [](void *p) { delete static_cast<QByteArray *>(p); });
        };
        setLevels(100); // A partial two-channel waveform must keep generating.
        QVERIFY(!copySplitWaveform(source, destination));
        setLevels(200);
        QVERIFY(copySplitWaveform(source, destination));
        auto copy = static_cast<QByteArray *>(destination.get_data(kAudioLevelsProperty));
        QCOMPARE(copy->size(), 200);
        setLevels(50); // Replacing the original must not invalidate the split half.
        QCOMPARE(*copy, QByteArray(200, 'a'));
        (*copy)[0] = 'b';
        auto original = static_cast<QByteArray *>(source.get_data(kAudioLevelsProperty));
        QCOMPARE(original->at(0), 'a');
    }
};
QTEST_GUILESS_MAIN(TestSplitWaveformCache)
#include "test_split_waveform_cache.moc"
