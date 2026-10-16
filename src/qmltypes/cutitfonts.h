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

#ifndef CUTITFONTS_H
#define CUTITFONTS_H
#include <functional>
#include <QNetworkAccessManager>
#include <QObject>
#include <QStringList>

class CutItFonts : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList families READ families NOTIFY familiesChanged)
    Q_PROPERTY(QStringList googleFamilies READ googleFamilies CONSTANT)
    Q_PROPERTY(bool busy READ busy NOTIFY statusChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
public:
    explicit CutItFonts(const QString &cache, const QString &bundled, QObject *parent = nullptr);
    ~CutItFonts() override;
    static void releaseAll();
    QStringList families() const;
    QStringList googleFamilies() const;
    bool busy() const { return m_busy; }
    QString status() const { return m_status; }
    Q_INVOKABLE void download(const QString &family);
signals:
    void familiesChanged();
    void statusChanged();

private:
    bool load(const QString &path);
    void release();
    QStringList m_registeredPaths;
    QList<int> m_fontIds;
    void request(const QUrl &url, std::function<void(QByteArray)> done);
    void finish(const QString &message);
    QNetworkAccessManager m_network;
    QString m_cache;
    QString m_status;
    bool m_busy = false;
};
#endif
