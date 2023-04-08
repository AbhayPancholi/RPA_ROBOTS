*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             OperatingSystem
Library             RPA.Tables
Library             RPA.Cloud.Azure
Library             RPA.RobotLogListener
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Desktop


*** Variables ***
${url}              https://robotsparebinindustries.com/#/robot-order
${csv_url}          https://robotsparebinindustries.com/orders.csv

${orders_file}      ${CURDIR}${/}exp.csv
${pdf_folder}       ${OUTPUT_DIR}${/}pdf_files
${output_folder}    ${CURDIR}${/}output
${zip_file}         ${output_folder}${/}pdf_archive.zip
${pdf_file_path}    ${output_folder}{/}pdf_files


*** Tasks ***
Order robots form RobotSpareBin Industries Inc
    Open the robot order website

    ${orders}=    Get orders

    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the orders form    ${row}

        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit the order
        TRY
            Sleep    2sec
            ${orderid}    ${img_name}=    Take screenshot of the robot
        EXCEPT
            Wait Until Keyword Succeeds    5x    5s    Submit the order
            ${orderid}    ${img_name}=    Take screenshot of the robot
        FINALLY
            TRY
                ${pdf_name}=    Wait Until Keyword Succeeds
                ...    10x
                ...    5s
                ...    Store order receipt as pdf
                ...    Order_num=${orderid}
            EXCEPT    message
                Wait Until Keyword Succeeds    5x    5s    Submit the order
                ${orderid}    ${img_name}=    Take screenshot of the robot
                ${pdf_name}=    Wait Until Keyword Succeeds
                ...    10x
                ...    5s
                ...    Store order receipt as pdf
                ...    Order_num=${orderid}
            END
            Embed the robot screenshot to the receipt PDF file    ${img_name}    ${pdf_name}
            Order another robot
        END
    END
    Create a ZIP file of receipt PDF files
    Close the browser


*** Keywords ***
Open the robot order website
    Open Available Browser    ${url}

Get orders
    Download    ${csv_url}    target_file=${orders_file}    overwrite=True
    ${table}=    Read table from CSV    path=${orders_file}
    RETURN    ${table}

Close the annoying modal
    Wait Until Element Is Visible    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Wait Until Element is Enabled    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Wait And Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill the orders form
    [Arguments]    ${row}

    Wait Until Element Is Visible    //*[@id="head"]
    Wait Until Element is Enabled    //*[@id="head"]

    Select From List By Value    //*[@id="head"]    ${row}[Head]

    Wait Until Element Is Enabled    body
    Select Radio Button    body    ${row}[Body]

    Wait Until Element Is Enabled    //html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Input Text    //html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]

    Wait Until Element Is Enabled    //*[@id="address"]
    Input Text    //*[@id="address"]    ${row}[Address]

Preview the robot
    Click Button    //*[@id="preview"]
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]

Submit the order
    Wait Until Element Is Enabled    //*[@id="order"]
    Click Button    //*[@id="order"]

Take screenshot of the robot
    Set Local Variable    ${image_xpath}    //*[@id="robot-preview-image"]
    Set Local Variable    ${receipt_xpath}    xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]

    Wait Until Element Is Visible    ${receipt_xpath}
    Wait Until Element Is Enabled    ${receipt_xpath}

    Wait Until Element Is Visible    ${image_xpath}
    Wait Until Element Is Enabled    ${image_xpath}

    Mute Run On Failure    ${receipt_xpath}
    Sleep    2sec
    ${order_id}=    Get Text    ${receipt_xpath}

    Set Local Variable    ${image_path}    ${OUTPUT_DIR}${/}${order_id}.png

    Sleep    1sec
    Capture Element Screenshot    ${image_xpath}    ${image_path}
    RETURN    ${order_id}    ${image_path}

Store order receipt as pdf
    [Arguments]    ${Order_num}
    Sleep    1sec

    Set Local Variable    ${full_pdf_path}    ${pdf_folder}${/}${Order_num}.pdf
    Set Local Variable    ${html_body}    //html/body/div/div/div[1]/div/div[1]/div
    Set Local Variable    ${receipt_id}    //*[@id="receipt"]

    Wait Until Element Is Visible    ${html_body}
    Wait Until Element Is Enabled    ${html_body}

    Wait Until Element Is Enabled    ${receipt_id}

    ${receipt_html}=    Get Element Attribute    ${receipt_id}    outerHTML
    Html To Pdf    content=${receipt_html}    output_path=${full_pdf_path}

    RETURN    ${full_pdf_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${Img_file}    ${Pdf_file}

    Open Pdf    ${Pdf_file}
    @{my_list}=    Create List    ${Img_file}
    Add Files To Pdf    ${my_list}    ${Pdf_file}    ${True}
    Close Pdf    ${Pdf_file}

Create a ZIP file of receipt PDF files
    # ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip

    Archive Folder With Zip
    ...    ${pdf_file_path}
    ...    ${zip_file}

Order another robot
    Mute Run On Failure    //*[@id="receipt"]
    Click Button    //*[@id="order-another"]

Close the Browser
    Close Browser
