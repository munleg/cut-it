// Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
#ifndef SILENCERANGES_H
#define SILENCERANGES_H
#include <cmath>
#include <QList>
#include <QPair>
#include <QRegularExpression>
#include <QString>

// Half-open frame intervals, rounded inward to preserve speech at boundaries.
inline QList<QPair<int, int>> silenceRanges(const QString &log,
                                            double fps,
                                            int frames,
                                            double padding)
{
    QList<QPair<int, int>> result;
    if (fps <= 0 || frames <= 0)
        return result;
    QRegularExpression re(QStringLiteral("silence_(start|end):\\s*([0-9]+(?:\\.[0-9]+)?)"));
    auto matches = re.globalMatch(log);
    double start = -1;
    auto append = [&](double end) {
        int a = qBound(0, int(std::ceil((start + padding) * fps)), frames);
        int b = qBound(0, int(std::floor((end - padding) * fps)), frames);
        if (b > a && (result.isEmpty() || a >= result.last().second))
            result.append(qMakePair(a, b));
    };
    while (matches.hasNext()) {
        auto match = matches.next();
        double value = match.captured(2).toDouble();
        if (match.captured(1) == QStringLiteral("start"))
            start = value;
        else if (start >= 0) {
            append(value);
            start = -1;
        }
    }
    if (start >= 0)
        append(frames / fps);
    return result;
}
#endif
