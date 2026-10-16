// Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
#include "cutitupdate.h"
#include <QtTest>

class TestCutItUpdate : public QObject
{
    Q_OBJECT
    QJsonObject release(QString tag, bool draft = false, QString host = "github.com")
    {
        return {{"tag_name", tag},
                {"draft", draft},
                {"prerelease", true},
                {"assets",
                 QJsonArray{QJsonObject{
                     {"name", "Cut-it-0.1-Beta-Setup.exe"},
                     {"state", "uploaded"},
                     {"size", 123},
                     {"browser_download_url",
                      QString(
                          "https://%1/munleg/cut-it/releases/download/%2/Cut-it-0.1-Beta-Setup.exe")
                          .arg(host, tag)}}}}};
    }
private slots:
    void versions()
    {
        using namespace CutItUpdate;
        QVERIFY(newer(parse("v0.1.0-beta.10"), parse("0.1.0-beta.2")));
        QVERIFY(newer(parse("0.1.0"), parse("0.1.0-rc.9")));
        QVERIFY(newer(parse("0.2.0-alpha.1"), parse("0.1.0")));
        QVERIFY(!newer(parse("0.1.0-beta.1"), parse("0.1.0-beta.2")));
        QVERIFY(!newer(parse("0.1.0-beta.2"), parse("0.1.0-beta.2")));
        QVERIFY(!parse("../bad").valid());
    }
    void betaSelectionIsNotChronological()
    {
        auto result = CutItUpdate::latest({release("v0.1.0-beta.3"),
                                           release("v0.1.0-beta.10"),
                                           release("v0.1.0-beta.2")},
                                          "0.1.0-beta.2");
        QCOMPARE(result.tag, QString("v0.1.0-beta.10"));
        QCOMPARE(result.page.host(), QString("github.com"));
    }
    void skipsDraftsMissingDownloadsAndForeignUrls()
    {
        auto missing = release("v0.4.0");
        missing.remove("assets");
        QVERIFY(CutItUpdate::latest({release("v0.2.0", true),
                                     release("v0.3.0", false, "example.com"),
                                     missing},
                                    "0.1.0-beta.2")
                    .tag.isEmpty());
        QVERIFY(CutItUpdate::latest({release("v0.1.0-beta.1")}, "0.1.0-beta.2").tag.isEmpty());
    }
};
QTEST_GUILESS_MAIN(TestCutItUpdate)
#include "test_cutit_update.moc"
