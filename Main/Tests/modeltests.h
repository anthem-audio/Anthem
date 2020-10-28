/*
    Copyright (C) 2019, 2020 Joshua Wade

    This file is part of Anthem.

    Anthem is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation, either version 3 of
    the License, or (at your option) any later version.

    Anthem is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with Anthem. If not, see
                        <https://www.gnu.org/licenses/>.
*/

#ifndef MODELTESTS_H
#define MODELTESTS_H

#include <QObject>
#include <QDebug>
#include <QtTest/QtTest>

#include "Presenter/mainpresenter.h"

Q_DECLARE_METATYPE(PatchFragment::PatchType);

class ModelTests : public QObject {
Q_OBJECT

private:
    IdGenerator* id;
    MainPresenter* presenter;
    Project* project;

private slots:
    void initTestCase() {
        id = new IdGenerator();
        presenter = new MainPresenter(this, id);

        project = presenter->getProjectAt(0);
    }

    void emptyProject() {
        qDebug() << "Initial project state";
        QCOMPARE(project->getTransport()->beatsPerMinute->get(), 140.0f);



        qDebug() << "Direct item set";

        // Set the value to -5, but send a live update instead of a patch.
        project->getTransport()->beatsPerMinute->set(-5.0f, false);

        // The control should report the newly set value.
        QCOMPARE(project->getTransport()->beatsPerMinute->get(), -5.0f);



        // Set the value to 10, and send a patch (final value in a channge operation).
        project->getTransport()->beatsPerMinute->set(10.0f, true);

        // The control should report the newly set value.
        QCOMPARE(project->getTransport()->beatsPerMinute->get(), 10.0f);
    }

    void presenterTests() {
        qDebug() << "Remove the current testing project and open a new one";
        presenter->removeProjectAt(0);
        presenter->newProject();


        qDebug() << "The new project should not be marked as having unsaved changes";
        QCOMPARE(presenter->projectHasUnsavedChanges(0), false);

        qDebug() << "Performing an action should add an undo step";
        presenter->setBeatsPerMinute(3, true);
        QCOMPARE(presenter->getBeatsPerMinute(), 3);
        QCOMPARE(presenter->projectHasUnsavedChanges(0), true);
        QCOMPARE(presenter->isProjectSaved(0), false);


        qDebug() << "Creating a new project should work as expected";
        presenter->newProject();
        qDebug() << "Checking for two open projects.";
        presenter->getProjectAt(0);
        presenter->getProjectAt(1);
        presenter->getEngineAt(1);
        presenter->getProjectFileAt(1);
        QCOMPARE(presenter->activeProjectIndex, 1);
        QCOMPARE(presenter->projectHasUnsavedChanges(0), true);
        QCOMPARE(presenter->isProjectSaved(0), false);
        QCOMPARE(presenter->projectHasUnsavedChanges(1), false);
        QCOMPARE(presenter->isProjectSaved(1), false);

        qDebug() << "We should be able to switch tabs";
        presenter->setBeatsPerMinute(6, true);
        presenter->setBeatsPerMinute(7, true);

        presenter->switchActiveProject(0);
        QCOMPARE(presenter->activeProjectIndex, 0);
        presenter->setBeatsPerMinute(6, true);
        presenter->setBeatsPerMinute(7, true);
        QCOMPARE(presenter->getBeatsPerMinute(), 7);

        qDebug() << "We should be able to close the first tab";
        presenter->closeProject(0);
        presenter->switchActiveProject(0);
        QCOMPARE(presenter->activeProjectIndex, 0);
        QCOMPARE(presenter->getBeatsPerMinute(), 9);

        qDebug() << "Save and load should work as expected";
        auto path = QDir::currentPath() + "/test.anthem";
        qDebug() << path;
        presenter->setBeatsPerMinute(10, true);
        presenter->saveActiveProjectAs(path);
        QCOMPARE(presenter->projectHasUnsavedChanges(0), false);
        QCOMPARE(presenter->isProjectSaved(0), true);
        presenter->loadProject(path);
        QCOMPARE(presenter->activeProjectIndex, 1);
        QCOMPARE(presenter->getBeatsPerMinute(), 10);
        QCOMPARE(presenter->projectHasUnsavedChanges(1), false);
        QCOMPARE(presenter->isProjectSaved(1), true);
        QCOMPARE(presenter->getProjectAt(presenter->activeProjectIndex)->getSong()->getPatterns().keys().length(), 1);

        presenter->setBeatsPerMinute(-12, true);
        QCOMPARE(presenter->projectHasUnsavedChanges(1), true);
        QCOMPARE(presenter->isProjectSaved(1), true);
        presenter->saveActiveProject();
        presenter->loadProject(path);
        QCOMPARE(presenter->activeProjectIndex, 2);
        QCOMPARE(presenter->getBeatsPerMinute(), -12);
        QCOMPARE(presenter->projectHasUnsavedChanges(1), false);
        QCOMPARE(presenter->isProjectSaved(1), true);
        QCOMPARE(presenter->projectHasUnsavedChanges(2), false);
        QCOMPARE(presenter->isProjectSaved(2), true);
        presenter->closeProject(2);
        presenter->closeProject(1);
        presenter->closeProject(0);
        presenter->newProject();
        presenter->switchActiveProject(0);

        QCOMPARE(presenter->activeProjectIndex, 0);



        qDebug() << "There should be one pattern by default";
        PatternPresenter& patternPresenter = *presenter->getPatternPresenter();
        Song& song = *presenter->getProjectAt(presenter->activeProjectIndex)->getSong();
        QCOMPARE(song.getPatterns().keys().length(), 1);
        QCOMPARE(song.getPatterns()[song.getPatterns().keys()[0]]->getDisplayName(), QString("New pattern"));

        qDebug() << "Pattern delete should work";
        patternPresenter.removePattern(song.getPatterns().keys()[0]);
        QCOMPARE(song.getPatterns().keys().length(), 0);

        qDebug() << "Pattern create should work";
        patternPresenter.createPattern("Test 1", QColor("#FFFFFF"));
        QCOMPARE(song.getPatterns().keys().length(), 1);
        QCOMPARE(song.getPatterns()[song.getPatterns().keys()[0]]->getDisplayName(), QString("Test 1"));
        QCOMPARE(song.getPatterns()[song.getPatterns().keys()[0]]->getColor(), QColor("#FFFFFF"));
        patternPresenter.createPattern("Test 2", QColor("#FFFFFF"));
        QCOMPARE(song.getPatterns().keys().length(), 2);
        patternPresenter.createPattern("Test 3", QColor("#FFFFFF"));
        QCOMPARE(song.getPatterns().keys().length(), 3);
    }

    void cleanupTestCase() {
        auto path = QDir::currentPath() + "/test.anthem";
        QFile file(path);
        file.remove();
    }
};

#endif // MODELTESTS_H
