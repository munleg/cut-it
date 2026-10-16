// Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
#include "models/silenceranges.h"
#include <QtTest>

class TestSilenceRanges : public QObject
{
    Q_OBJECT
private slots:
    void preservesPaddingAndRoundsInward()
    {
        auto r = silenceRanges("silence_start: 1.01\nsilence_end: 2.09", 30, 120, 0.16);
        QCOMPARE(r.size(), 1);
        QCOMPARE(r[0].first, 33);
        QCOMPARE(r[0].second, 60);
    }
    void trailingSilenceAndBounds()
    {
        auto r = silenceRanges("silence_start: 3", 30, 120, 0);
        QCOMPARE(r, (QList<QPair<int, int>>{{90, 120}}));
        QVERIFY(silenceRanges("silence_start: 9", 30, 120, 0).isEmpty());
    }
    void ignoresErrorsAndShortIntervals()
    {
        QVERIFY(silenceRanges("No audio stream", 30, 120, 0).isEmpty());
        QVERIFY(silenceRanges("silence_end: 2", 30, 120, 0).isEmpty());
        QVERIFY(silenceRanges("silence_start: 1\nsilence_end: 1.1", 30, 120, 0.2).isEmpty());
    }
    void retainsRequestedTotalGap()
    {
        const QString log = "silence_start: 1\nsilence_end: 2";
        auto r = silenceRanges(log, 30, 120, 0.2);
        QCOMPARE(r, (QList<QPair<int, int>>{{33, 57}}));
        r = silenceRanges(log, 30, 120, 0.1);
        QCOMPARE(r, (QList<QPair<int, int>>{{32, 58}}));
        QVERIFY(silenceRanges(log, 30, 120, 1.1).isEmpty());
        QVERIFY(silenceRanges(log, 30, 120, -0.1).isEmpty());
    }
    void multipleIntervalsAndFractionalRate()
    {
        auto r = silenceRanges("silence_start: 0\nsilence_end: 1\nsilence_start: 2\nsilence_end: 3",
                               29.97,
                               120,
                               0);
        QCOMPARE(r, (QList<QPair<int, int>>{{0, 29}, {60, 89}}));
    }
};
QTEST_GUILESS_MAIN(TestSilenceRanges)
#include "test_silence_ranges.moc"
