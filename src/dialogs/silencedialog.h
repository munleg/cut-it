/*
 * Copyright (C) 2026 Cut-it contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef SILENCEDIALOG_H
#define SILENCEDIALOG_H

#include <QAbstractItemView>
#include <QDialog>
#include <QDoubleSpinBox>
#include <QHBoxLayout>
#include <QLabel>
#include <QListWidget>
#include <QPushButton>
#include <QVBoxLayout>

// UI-only dialog used to configure and review silence removal.
//
// This class contains no detection or editing logic. The caller is expected to
// connect scanButton and deleteButton to its own slots, read the parameter
// widgets, populate ranges with the detected silent intervals, and enable
// deleteButton once a scan has produced results.
//
// Behaviour that the dialog documents to the user:
//   * Analysis is performed on the source audio of the selected clip.
//   * Deleting only removes the selected regions from that one clip.
//   * Later clips on the same track move left to fill the gap.
//   * Clips on other tracks are left unchanged.
//
// The ranges list supports multi-selection so several silent intervals can be
// removed at once. No keyboard shortcuts are installed here; the caller adds
// any configurable shortcuts it needs.
class SilenceDialog : public QDialog
{
public:
    explicit SilenceDialog(QWidget *parent = nullptr)
        : QDialog(parent)
    {
        setWindowTitle(tr("Find silence"));

        // Parameters.
        threshold = new QDoubleSpinBox(this);
        threshold->setRange(-60.0, -10.0);
        threshold->setDecimals(1);
        threshold->setSingleStep(1.0);
        threshold->setValue(-35.0);
        threshold->setSuffix(tr(" dB"));

        minimum = new QDoubleSpinBox(this);
        minimum->setRange(0.1, 10.0);
        minimum->setDecimals(2);
        minimum->setSingleStep(0.1);
        minimum->setValue(0.5);
        minimum->setSuffix(tr(" s"));

        padding = new QDoubleSpinBox(this);
        padding->setRange(0.0, 1.0);
        padding->setDecimals(2);
        padding->setSingleStep(0.01);
        padding->setValue(0.08);
        padding->setSuffix(tr(" s"));

        QVBoxLayout *layout = new QVBoxLayout(this);

        QHBoxLayout *parameters = new QHBoxLayout;
        parameters->addWidget(new QLabel(tr("Threshold:"), this));
        parameters->addWidget(threshold);
        parameters->addSpacing(8);
        parameters->addWidget(new QLabel(tr("Minimum duration:"), this));
        parameters->addWidget(minimum);
        parameters->addSpacing(8);
        parameters->addWidget(new QLabel(tr("Padding:"), this));
        parameters->addWidget(padding);
        parameters->addStretch();
        layout->addLayout(parameters);

        scanButton = new QPushButton(tr("Find silence"), this);
        layout->addWidget(scanButton);

        ranges = new QListWidget(this);
        ranges->setSelectionMode(QAbstractItemView::ExtendedSelection);
        ranges->setUniformItemSizes(true);
        layout->addWidget(ranges, 1);

        status = new QLabel(this);
        status->setWordWrap(true);
        layout->addWidget(status);

        QLabel *info = new QLabel(tr("Analysis uses the source audio of the selected clip. "
                                     "Deleting removes only the selected regions from that clip: "
                                     "later clips on this track move left to fill the gap, while "
                                     "clips on other tracks are unchanged."),
                                  this);
        info->setWordWrap(true);
        layout->addWidget(info);

        QHBoxLayout *buttons = new QHBoxLayout;
        buttons->addStretch();
        deleteButton = new QPushButton(tr("Delete selected"), this);
        deleteButton->setEnabled(false);
        buttons->addWidget(deleteButton);
        QPushButton *closeButton = new QPushButton(tr("Close"), this);
        buttons->addWidget(closeButton);
        layout->addLayout(buttons);

        connect(closeButton, &QPushButton::clicked, this, &QDialog::reject);
    }

    QDoubleSpinBox *threshold = nullptr;
    QDoubleSpinBox *minimum = nullptr;
    QDoubleSpinBox *padding = nullptr;

    QPushButton *scanButton = nullptr;
    QPushButton *deleteButton = nullptr;

    QListWidget *ranges = nullptr;
    QLabel *status = nullptr;
};

#endif // SILENCEDIALOG_H
