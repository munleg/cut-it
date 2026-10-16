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

#include "qmltypes/cutitfonts.h"
#include <QGuiApplication>
#include <QFontDatabase>
#include <QProcess>
#include <QTemporaryDir>
#include <QDir>
#include <QFile>
#include <QtTest>
#ifdef Q_OS_WIN
#include <qt_windows.h>
#endif

class TestCutItFonts : public QObject
{
    Q_OBJECT
private slots:
    void installationFontsRemainReplaceable()
    {
#ifdef Q_OS_WIN
        QTemporaryDir bundled;
        QTemporaryDir cache;
        const QDir original(QStringLiteral(CUTIT_TEST_FONTS));
        for (const auto &name : original.entryList({"*.ttf"}, QDir::Files))
            QVERIFY(QFile::copy(original.filePath(name), QDir(bundled.path()).filePath(name)));
        CutItFonts fonts(cache.path(), bundled.path());
        QVERIFY(fonts.families().contains("Bebas Neue"));
        const auto writable = [](const QString &path) {
            HANDLE file = CreateFileW(reinterpret_cast<LPCWSTR>(QDir::toNativeSeparators(path).utf16()),
                GENERIC_WRITE, 0, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
            if (file == INVALID_HANDLE_VALUE)
                return false;
            CloseHandle(file);
            return true;
        };
        const QDir install(bundled.path());
        for (const auto &name : install.entryList({"*.ttf"}, QDir::Files))
            QVERIFY2(writable(install.filePath(name)), qPrintable(name));
        CutItFonts::releaseAll();
        CutItFonts::releaseAll(); // Shutdown and normal destruction are both safe.
        const QDir registered(QDir(cache.path()).filePath("registered"));
        QVERIFY(!registered.entryList({"*.ttf"}, QDir::Files).isEmpty());
        for (const auto &name : registered.entryList({"*.ttf"}, QDir::Files))
            QVERIFY2(writable(registered.filePath(name)), qPrintable(name));
#endif
    }
    void offlineFontsAndExportProcess()
    {
        QTemporaryDir cache;
        CutItFonts fonts(cache.path(), QStringLiteral(CUTIT_TEST_FONTS));
        for (const auto &family : {"Lato", "Noto Sans", "Bebas Neue"})
            QVERIFY2(fonts.families().contains(family), family);
        fonts.download("Lato"); // Already cached: no network needed.
        QVERIFY(!fonts.busy());
        QVERIFY(fonts.status().contains("ready"));
#ifdef Q_OS_WIN
        QProcess probe;
        probe.start(QCoreApplication::applicationFilePath(), {"--font-probe"});
        QVERIFY(probe.waitForFinished(15000));
        QCOMPARE(probe.exitCode(), 0);
#endif
    }
};

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    if (app.arguments().contains("--font-probe"))
        return QFontDatabase::families().contains("Lato") ? 0 : 1;
    if (app.arguments().contains("--download-test")) {
        QTemporaryDir cache;
        CutItFonts fonts(cache.path(), QString());
        fonts.download("Pacifico");
        QElapsedTimer timer;
        timer.start();
        while (fonts.busy() && timer.elapsed() < 65000) {
            app.processEvents();
            QTest::qWait(20);
        }
        qInfo() << fonts.status();
        return fonts.families().contains("Pacifico") && !fonts.busy() ? 0 : 2;
    }
    TestCutItFonts test;
    return QTest::qExec(&test, argc, argv);
}
#include "test_cutit_fonts.moc"
