// Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
#ifndef CUTITUPDATE_H
#define CUTITUPDATE_H
#include <QJsonArray>
#include <QJsonObject>
#include <QRegularExpression>
#include <QUrl>
#include <QVersionNumber>

namespace CutItUpdate {
// Advance this for each distributable build; independent of the upstream MLT version.
inline constexpr char currentVersion[] = "0.1.2";
struct Version
{
    QVersionNumber number;
    int stage = -1;
    int sequence = 0;
    bool valid() const { return stage >= 0; }
};
inline Version parse(const QString &text)
{
    static const QRegularExpression pattern(
        QStringLiteral("^v?(\\d+\\.\\d+\\.\\d+)(?:-(alpha|beta|rc)\\.(\\d+))?$"));
    auto match = pattern.match(text);
    if (!match.hasMatch())
        return {};
    Version result;
    result.number = QVersionNumber::fromString(match.captured(1));
    const auto label = match.captured(2);
    result.stage = label.isEmpty() ? 3 : label == "rc" ? 2 : label == "beta" ? 1 : 0;
    result.sequence = match.captured(3).toInt();
    return result;
}
inline bool newer(const Version &a, const Version &b)
{
    if (!a.valid() || !b.valid())
        return false;
    const int compare = QVersionNumber::compare(a.number, b.number);
    return compare ? compare > 0 : a.stage != b.stage ? a.stage > b.stage : a.sequence > b.sequence;
}
struct Release
{
    QString tag;
    QUrl page;
};
enum class Platform { Windows, LinuxX64, Unsupported };
inline Platform currentPlatform()
{
#if defined(Q_OS_WIN)
    return Platform::Windows;
#elif defined(Q_OS_LINUX) && defined(Q_PROCESSOR_X86_64)
    return Platform::LinuxX64;
#else
    return Platform::Unsupported;
#endif
}
inline Release latest(const QJsonArray &releases, const QString &installed,
                      Platform platform = currentPlatform())
{
    if (platform == Platform::Unsupported)
        return {};
    const QRegularExpression assetPattern(platform == Platform::Windows
        ? QStringLiteral("^Cut-it-[A-Za-z0-9.-]+-Setup\\.exe$")
        : QStringLiteral("^Cut-it-[A-Za-z0-9.-]+-linux-x86_64\\.(AppImage|tar\\.xz)$"));
    auto best = parse(installed);
    Release result;
    for (const auto &value : releases) {
        const auto release = value.toObject();
        if (release.value("draft").toBool())
            continue;
        const auto tag = release.value("tag_name").toString();
        const auto version = parse(tag);
        if (!newer(version, best))
            continue;
        bool hasInstaller = false;
        for (const auto &assetValue : release.value("assets").toArray()) {
            const auto asset = assetValue.toObject();
            const auto name = asset.value("name").toString();
            if (!assetPattern.match(name).hasMatch())
                continue;
            const QUrl url(asset.value("browser_download_url").toString());
            if (asset.value("state").toString() == "uploaded" && asset.value("size").toDouble() > 0
                && url.scheme() == "https" && url.host() == "github.com" && url.userInfo().isEmpty()
                && url.port() == -1 && !url.hasQuery() && !url.hasFragment()
                && url.path()
                       == QStringLiteral("/munleg/cut-it/releases/download/%1/%2").arg(tag, name))
                hasInstaller = true;
        }
        if (!hasInstaller)
            continue;
        best = version;
        result = {tag,
                  QUrl(QStringLiteral("https://github.com/munleg/cut-it/releases/tag/%1").arg(tag))};
    }
    return result;
}
} // namespace CutItUpdate
#endif
