// Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
#ifndef SILENCERANGES_H
#define SILENCERANGES_H
#include <cmath>
#include <QList>
#include <QPair>
#include <QRegularExpression>
#include <QString>

// Half-open deletion intervals, rounded inward to preserve speech at boundaries.
// keepGap is the TOTAL pause retained, shared equally between both edges.
inline QList<QPair<int, int>> silenceRanges(const QString &log,
                                            double fps,
                                            int frames,
                                            double keepGap)
{
    QList<QPair<int, int>> result;
    if (!std::isfinite(fps) || fps <= 0 || frames <= 0 || !std::isfinite(keepGap) || keepGap < 0)
        return result;
    const double padding = keepGap / 2.0;
    QRegularExpression re(QStringLiteral("silence_(start|end):\\s*([0-9]+(?:\\.[0-9]+)?)"));
    auto matches = re.globalMatch(log);
    double start = -1;
    auto append = [&](double end) {
        int a = int(std::ceil(qBound(0.0, (start + padding) * fps, double(frames))));
        int b = int(std::floor(qBound(0.0, (end - padding) * fps, double(frames))));
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
