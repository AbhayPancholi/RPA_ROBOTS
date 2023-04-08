*** Settings ***
Documentation       Inhuman Insurance, Inc. Artificial Intelligence System robot.
...                 Shared settings and code.

Library             RPA.Robocorp.WorkItems
Library             RPA.JSON
Library             RPA.HTTP


*** Variables ***
${WORK_ITEM_NAME}       traffic_data


*** Tasks ***
Minimal task
    Log    Done.
