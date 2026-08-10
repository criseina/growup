# GrowUp Prototype Beta Test Guide

## Goal

Confirm that a parent can create a profile, choose an action, save an observation, and find that observation again without assistance.

## Install

1. Copy `build/app/outputs/flutter-apk/app-release.apk` to an Android phone.
2. Open the file and allow installation from the file manager if Android asks.
3. Open GrowUp. The app uses only local device storage in this prototype.

## Test flow

1. Complete the first-run introduction and enter a child nickname.
2. Open today's recommendation or `오늘 해볼 행동`.
3. Choose `개인 위생` and open `손 씻기`.
4. Select one of the three child-mode answers.
5. Open parent mode and enter a memo.
6. Open `내 성장 기록`; verify the new record, summary, and 7-day filter.
7. Edit the record, add an observation memo, then verify that the change remains after restarting the app.
8. Add a second child profile; verify that its records and notes are separate.

## Feedback to collect

- Which screen was unclear or difficult to find?
- Did the wording feel supportive rather than evaluative?
- Were the card order and today's recommendation appropriate?
- Was any text too small or any button hard to tap?
- Did anything fail to save after closing and reopening the app?

## Safety note

This app records everyday observations; it does not provide medical, developmental, or safety advice. Do not use it in place of professional support.
