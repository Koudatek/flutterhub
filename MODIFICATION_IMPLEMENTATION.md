# Modification Implementation Plan

This document outlines the steps to refactor the application to a feature-first architecture with GoRouter and Riverpod.

## Journal

*   **2025-11-13:** Initial plan created.

## Phase 1: Project Setup and Initial Refactoring

*   [ ] Run all tests to ensure the project is in a good state before starting modifications.
*   [ ] Add `go_router` and `flutter_riverpod` dependencies to `pubspec.yaml`.
*   [ ] Create the new directory structure as outlined in the design document.
*   [ ] Move existing files to their new locations in the feature-first structure.
*   [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
*   [ ] Run the `dart_fix` tool to clean up the code.
*   [ ] Run the `analyze_files` tool one more time and fix any issues.
*   [ ] Run any tests to make sure they all pass.
*   [ ] Run `dart_format` to make sure that the formatting is correct.
*   [ ] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [ ] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After committing the change, if an app is running, use the `hot_reload` tool to reload it.

## Phase 2: Navigation Refactoring with GoRouter

*   [ ] Create the main `GoRouter` configuration in `lib/core/navigation/app_router.dart`.
*   [ ] For each feature, create a `*_routes.dart` file that defines the feature's routes.
*   [ ] Refactor the application's entry point in `main.dart` to use `MaterialApp.router`.
*   [ ] Replace all existing `Navigator.push/pop` calls with `context.go`, `context.push`, etc.
*   [ ] Implement authentication redirects using `GoRouter`'s `redirect` functionality.
*   [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
*   [ ] Run the `dart_fix` tool to clean up the code.
*   [ ] Run the `analyze_files` tool one more time and fix any issues.
*   [ ] Run any tests to make sure they all pass.
*   [ ] Run `dart_format` to make sure that the formatting is correct.
*   [ ] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [ ] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After committing the change, if an app is running, use the `hot_reload` tool to reload it.

## Phase 3: State Management Refactoring with Riverpod

*   [ ] For each feature, create providers for the feature's state and business logic in the `presentation/providers` directory.
*   [ ] Refactor the UI to use the new Riverpod providers.
*   [ ] Replace any existing state management solutions (e.g., `setState`, `ChangeNotifier`) with Riverpod.
*   [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
*   [ ] Run the `dart_fix` tool to clean up the code.
*   [ ] Run the `analyze_files` tool one more time and fix any issues.
*   [ ] Run any tests to make sure they all pass.
*   [ ] Run `dart_format` to make sure that the formatting is correct.
*   [ ] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [ ] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After committing the change, if an app is running, use the `hot_reload` tool to reload it.

## Phase 4: Finalization

*   [ ] Update any `README.md` file for the package with relevant information from the modification (if any).
*   [ ] Update any `GEMINI.md` file in the project directory so that it still correctly describes the app, its purpose, and implementation details and the layout of the files.
*   [ ] Ask the user to inspect the. package (and running app, if any) and say if they are satisfied with it, or if any modifications are needed.


En faite la premiere fonction , c'est de pouvoir installer en un et quelque clics , tous ceux dont on a besoin pour dévélopper avec flutter , donc le but c'est qu'après réussite de notre fonctionnalité , flutter doctor passe , 
On peut permettre à l'utilisateur de selectionner les platformes pour lequel il veut travail , et en fonction les composants sont selectionnés ou désélectionnés automatiquement 