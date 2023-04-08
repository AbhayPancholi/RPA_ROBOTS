*** Settings ***
Documentation       Inhuman Insurance, Inc. Artificial Intelligence System robot.
...                 Produces traffic data work items.

Library             RPA.JSON
Library             RPA.Tables
Library             Collections
Resource            shared.robot


*** Variables ***
${json_file_path}       ${CURDIR}${/}traffic.json
#json payload keys
${COUNTRY_KEY}          SpatialDim
${GENDER_KEY}           Dim1
${RATE_KEY}             NumericValue
${YEAR_KEY}             TimeDim


*** Tasks ***
Produce traffic data work items
    # Download traffic data
    ${traffic_data}    Load traffic data as table
    # Write table to CSV    ${traffic_data}    test.csv
    ${filtered_data}    Filter and sort traffic data    ${traffic_data}
    ${filtered_data}    Get latest data by country    ${filtered_data}
    ${payloads}    Create work items payloads    ${filtered_data}


*** Keywords ***
Download traffic data
    Download
    ...    https://github.com/robocorp/inhuman-insurance-inc/raw/main/RS_198.json
    ...    ${json_file_path}
    ...    overwrite=True

Load traffic data as table
    ${json}    Load JSON from file    ${json_file_path}
    ${table}    Create Table    ${json}[value]
    RETURN    ${table}

Filter and sort traffic data
    [Arguments]    ${table}

    ${max_rate}    Set Variable    ${5.0}
    ${gender_value}    Set Variable    BTSX
    ${year_key}    Set Variable    TimeDim

    Filter Table By Column    ${table}    ${RATE_KEY}    <    ${max_rate}
    Filter Table By Column    ${table}    ${GENDER_KEY}    ==    ${gender_value}
    Sort Table By Column    ${table}    ${YEAR_KEY}    ${False}
    RETURN    ${table}

Get latest data by country
    [Arguments]    ${table}
    ${table}    Group Table By Column    ${table}    ${COUNTRY_KEY}
    ${latest_data_by_country}    Create List

    FOR    ${group}    IN    @{table}
        ${first_row}    Pop Table Row    ${group}
        Append To List    ${latest_data_by_country}    ${first_row}
    END
    RETURN    ${latest_data_by_country}

Create work items payloads
    [Arguments]    ${traffic_data}
    ${payloads}    Create List

    FOR    ${row}    IN    @{traffic_data}
        ${payload}    Create Dictionary
        ...    country=${row}[${COUNTRY_KEY}]
        ...    year=${row}[${YEAR_KEY}]
        ...    rate=${row}[${RATE_KEY}]
        Append To List    ${payloads}    ${payload}
    END
    RETURN    ${payloads}

Save work items payloads
    [Arguments]    ${payloads}
    FOR    ${element}    IN    @{payloads}
        Log    ${element}
    END

Save work items payload
    [Arguments]    ${payload}
    ${variables}    Create Dictionary    ${WORK_ITEM_NAME}=${payload}
    Create Output Work Item    variables=${variables}    save=True
