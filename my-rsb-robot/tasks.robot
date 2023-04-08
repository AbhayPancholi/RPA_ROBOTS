*** Settings ***
Documentation       Insert the sales data for the week and export it as a pdf

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF


*** Tasks ***
Insert the sales data for the week and export it as a pdf
    Open the intranet website
    Log in
    Download the Excel File
    Fill the form using data from the excel file
    Collect the results
    Export the table as pdf
    [Teardown]    Logout and close the browser


*** Keywords ***
Open the intranet website
    Open Available Browser    https://robotsparebinindustries.com/

Log in
    Input Text    username    maria
    Input Password    password    thoushallnotpass
    Submit Form
    Wait Until Page Contains Element    id:sales-form

Download the Excel File
    Download    https://robotsparebinindustries.com/SalesData.xlsx    overwrite=True

Fill the form using data from the excel file
    Open Workbook    SalesData.xlsx
    ${sales_reps}=    Read Worksheet As Table    header=True
    Close Workbook
    FOR    ${sales_reps}    IN    @{sales_reps}
        Fill and submit the form    ${sales_reps}
    END

Fill and submit the form
    [Arguments]    ${sales_reps}
    Input Text    firstname    ${sales_reps}[First Name]
    Input Text    lastname    ${sales_reps}[Last Name]
    Input Text    salesresult    ${sales_reps}[Sales]
    Select From List By Value    salestarget    ${sales_reps}[Sales Target]
    Click Button    Submit

Collect the results
    Screenshot    css:div.sales-summary    ${OUTPUT_DIR}${/}sales_summary.png

Export the table as pdf
    Wait Until Element Is Visible    id:sales-results
    ${sales_result_html}=    Get Element Attribute    id:sales-results    outerHTML
    Html To Pdf    ${sales_result_html}    ${OUTPUT_DIR}${/}sales_results.pdf

Logout and close the browser
    Click Button    Log out
    Close Browser
