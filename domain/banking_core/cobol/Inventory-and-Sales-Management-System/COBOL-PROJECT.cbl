       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROJECT.
       AUTHOR. GROUP 4: ANDADOR, CRUZ, LIPATA, and LOPEZ. DIT 2-1.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.   
       FILE-CONTROL.
           SELECT P-PRODUCTS-FILE ASSIGN TO "PRODUCTS.DAT"
      *    INDEX FILE FOR FASTER SEARCH
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS P-PRODUCT-ID
               FILE STATUS IS P-PRODUCTS-STATUS.

      *    SEQUENTIAL FILE TO STORE IN A FIXED ORDER      
           SELECT S-SALES-FILE ASSIGN TO "SALES.DAT"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS S-SALES-STATUS.

       DATA DIVISION.
       FILE SECTION.
      *    DATABASE FILE FOR PRODUCTS
       FD  P-PRODUCTS-FILE.
       01  P-PRODUCTS-RECORD.
           05  P-PRODUCT-ID            PIC X(10).
           05  P-PRODUCT-NAME          PIC X(30).
           05  P-COST-PER-UNIT         PIC S9(6)V99.
           05  P-UNIT-PRICE            PIC S9(6)V99.
           05  P-STOCK                 PIC S9(5).
           05  P-DATE-ADDED            PIC S9(8).
      
      *    DATABASE FILE FOR SALES
       FD  S-SALES-FILE.
       01  SALES-RECORD.
           05  S-PRODUCT-ID            PIC X(10).
           05  S-PRODUCT-NAME          PIC X(30).
           05  S-SOLD-UNITS            PIC S9(5).
           05  S-UNIT-PRICE            PIC S9(6)V99.
           05  S-TOTAL-AMOUNT          PIC S9(8)V99.
           05  S-COST-OF-GOODS         PIC S9(8)V99.
           05  S-PROFIT                PIC S9(8)V99.
           05  S-SALE-DATE             PIC S9(8).

       WORKING-STORAGE SECTION.
      *    SAVES THE DEVICE'S OS
       01  WS-OS-NAME                      PIC X(50).
       
      *    MAIN MENU OPTION
       01  MAIN-CHOICE                 PIC S9(9).
               
      *    DATABASE VIEW OPTIONS
       01  IS-CHOICE                   PIC S9(9).

      *    UPDATE PRODUCT OPTION
       01  P-UPDATE-CHOICE             PIC S9(9).

       01  RESET-SALES                 PIC A.

       01  RESET-PRODUCTS              PIC A.

      *    CONTINUATION OF ACTION
       01  CONTINUE-ANOTHER            PIC A.

       01  CONTINUE-SALE               PIC A.

       01  WS-FIELD-INFO.
      *    HOLDS USER INPUT BEFORE SANITIZATION. 
           05 WS-FIELD-NAME        PIC X(30).
      *    SANITIZED USER INPUT.
           05 WS-FIELD-VALUE       PIC X(30).

      *    USER INPUT FLAG. 
       01  WS-VALIDATION-FLAGS.
           05 WS-IS-VALID          PIC X VALUE 'N'.
              88 VALID-INPUT       VALUE 'Y'.
              88 INVALID-INPUT     VALUE 'N'.
           05 WS-USER-CHOICE       PIC X.
              88 USER-CANCELLED    VALUE 'N' 'n'.
              88 USER-RETRY        VALUE 'Y' 'y'.

      *    PRODUCT DATABASE END DETECTION.
       01  P-PRODUCTS-STATUS           PIC XX.
           88  PRODUCTS-OK             VALUE "00".
           88  PRODUCTS-EOF            VALUE "10".
           
       01  S-SALES-STATUS              PIC XX.
           88  SALES-OK                VALUE "00".
           88  SALES-EOF               VALUE "10".

      *    MAIN USER INPUT
       01  INPUT-FIELDS.
           05  I-PRODUCT-ID            PIC X(10).
           05  I-PRODUCT-NAME          PIC X(30).
           05  I-COST-PER-UNI          PIC S9(6)V99.
           05  I-UNIT-PRICE            PIC S9(6)V99.
           05  I-STOCK                 PIC S9(5).
           05  I-SOLD-UNITS            PIC S9(5).
           
      *    AGGREGATED DATA FOR DASHBOARD DISPLAY.
       01  DASHBOARD-TOTALS.
           05  DT-TOTAL-PRODUCTS       PIC S9(5) VALUE ZERO.
           05  DT-TOTAL-STOCK          PIC S9(8) VALUE ZERO.
           05  DT-TOTAL-REVENUE        PIC S9(10)V99 VALUE ZERO.
           05  DT-TOTAL-PROFIT         PIC S9(10)V99 VALUE ZERO.
           05  DT-TOTAL-QTY-SOLD       PIC S9(8) VALUE ZERO.
           05  DT-PROFIT-MARGIN        PIC S9(3)V99 VALUE ZERO.
           
      *    TEMPORARY CALCULATIONS IN RECORDING SALES. 
       01  CALCULATION-FIELDS.
           05  CF-SALE-AMOUNT          PIC S9(8)V99.
           05  CF-COST-AMOUNT          PIC S9(8)V99.
           05  CF-PROFIT-AMOUNT        PIC S9(8)V99.
           
      *    PROPER DISPLAY.        
       01  DISPLAY-FIELD.
           05 DF-PUNIT-PRICE           PIC ZZZ,ZZZ,ZZ9.99.
           05  DF-DISP-AMOUNT          PIC ZZZ,ZZZ,ZZ9.99.
           05  DF-DISP-QTY             PIC ZZZ,ZZ9.
           05  DF-DISP-PERCENTAGE      PIC ZZ9.99.
           05  DF-S-PROFIT             PIC ZZZ,ZZZ,ZZ9.99.
           05  DF-PSTOCK               PIC ZZZZZZ.
           05  DF-PCOST-PER-UNIT       PIC ZZZ,ZZZ,ZZ9.99.

      *    CALCULATION AND STORING OF PRODUCT SALE SUMMARY
       01  PRODUCT-REVENUE-TOTALS.
           05  PR-TOTAL-REVENUE        PIC S9(10)V99 VALUE ZERO.
           05  PR-TOTAL-PROFIT         PIC S9(10)V99 VALUE ZERO.
           05  PR-TOTAL-SOLD           PIC S9(8) VALUE ZERO.
           05  PR-TIMES-SOLD           PIC S9(5) VALUE ZERO.

      *    USED TO CALCULATE CURRENT DATE.
       01  CURRENT-DATE.
           05  CD-YEAR                 PIC 9(4).
           05  CD-MONTH                PIC 9(2).
           05  CD-DAY                  PIC 9(2).
       01  DATE-DISPLAY                PIC ZZ,ZZ,ZZZZ.

       PROCEDURE DIVISION.
      *    MAIN INTERFACE OF THE SYSTEM
       MENU-MAIN.
           PERFORM CLEAR-SCREEN.
           PERFORM DISPLAY-DASHBOARD.
           PERFORM STOCK-DISPLAY.
           DISPLAY "            CURRENT DATE: " DATE-DISPLAY.
           DISPLAY "=================================================="
           DISPLAY "|    INVENTORY AND SALES MANAGEMENT SYSTEM       |".
           DISPLAY "|------------------------------------------------|"
           DISPLAY "| 1. Add new product                             |".
           DISPLAY "| 2. Update product information                  |".
           DISPLAY "| 3. Record a sale                               |".
           DISPLAY "| 4. Income statement                            |".
           DISPLAY "| 5. View product details                        |".
           DISPLAY "| 6. Reset Sales Database                        |".
           DISPLAY "| 7. Reset Products Database                     |".
           DISPLAY "|                                                |".
           DISPLAY "| 9. Exit                                        |".
           DISPLAY "==================================================".
           DISPLAY "Please select an option: " WITH NO ADVANCING.
           ACCEPT MAIN-CHOICE.
      
      *    CALLS THE FUNCTION CORRESPONDING TO CHOICE
           EVALUATE MAIN-CHOICE
                WHEN 1
                    PERFORM CLEAR-SCREEN
                    PERFORM PRODUCT-ADD
                WHEN 2
                    PERFORM CLEAR-SCREEN
                    PERFORM UPDATE-PRODUCT-MENU
                WHEN 3
                    PERFORM CLEAR-SCREEN
                    PERFORM RECORD-SALES
                WHEN 4
                    PERFORM CLEAR-SCREEN
                    PERFORM INCOME-STATEMENT
                    ACCEPT OMITTED
                    PERFORM MENU-MAIN
                WHEN 5
                    PERFORM CLEAR-SCREEN
                    PERFORM VIEW-PRODUCT-DETAILS-MENU
                WHEN 6
                    PERFORM SALES-RESET
                WHEN 7
                    PERFORM CLEAR-SCREEN
                    PERFORM PRODUCTS-RESET
                WHEN 9
                    PERFORM PROG-TERMINATE
                WHEN OTHER
                    PERFORM MENU-MAIN
           END-EVALUATE.

      *    ADD PRODUCT
       PRODUCT-ADD.
           PERFORM STOCK-DISPLAY
           DISPLAY "=================================================="
           DISPLAY "                 ADD NEW PRODUCT"
           DISPLAY "=================================================="

      *    PRODUCT DATA INPUT
      *    PRODUCT ID INPUT
           MOVE "Enter Product ID" TO WS-FIELD-NAME
      *    VALIDATES INPUT
           PERFORM GET-TEXT-INPUT
               IF USER-CANCELLED
                    PERFORM CLEAR-SCREEN
                    DISPLAY "                Cancelled."
                    PERFORM MENU-MAIN
               END-IF
               MOVE WS-FIELD-VALUE TO I-PRODUCT-ID
 
               MOVE I-PRODUCT-ID TO P-PRODUCT-ID
               READ P-PRODUCTS-FILE
                   INVALID KEY CONTINUE
      *    CHECKS FOR DUPLICATE DATA
                   NOT INVALID KEY
                       PERFORM CLEAR-SCREEN
                       DISPLAY "Product ID already exists!"
                       PERFORM SHOW-VALIDATION-ERROR
      *    RETURNS TO MAIN MENU IF CANCELLED
                   IF USER-CANCELLED 
                       PERFORM CLEAR-SCREEN
                       DISPLAY "                Cancelled."
                       PERFORM MENU-MAIN
      *    RECALLS FUNCTION IF INVALID INPUT FOR RETRY
                   ELSE
                       PERFORM CLEAR-SCREEN
                       PERFORM PRODUCT-ADD
                   END-IF
               END-READ

      *    PRODUCT NAME          
               MOVE "Enter Product Name" TO WS-FIELD-NAME
               PERFORM GET-TEXT-INPUT
                   IF USER-CANCELLED 
                       PERFORM CLEAR-SCREEN
                       DISPLAY "                Cancelled."
                       PERFORM MENU-MAIN
                   END-IF
               MOVE WS-FIELD-VALUE TO I-PRODUCT-NAME

      *    COST PER UNIT
               MOVE "Enter Cost Per Unit" TO WS-FIELD-NAME
               PERFORM GET-NUMERIC-INPUT
                   IF USER-CANCELLED
                    PERFORM CLEAR-SCREEN
                    DISPLAY "                Cancelled."
                    PERFORM MENU-MAIN
               END-IF
               MOVE FUNCTION NUMVAL(WS-FIELD-VALUE) TO I-COST-PER-UNI
          
      *    UNIT PRICE
           MOVE "Enter Unit Price" TO WS-FIELD-NAME
           PERFORM GET-NUMERIC-INPUT
               IF USER-CANCELLED
                    PERFORM CLEAR-SCREEN
                    DISPLAY "                Cancelled."
                    PERFORM MENU-MAIN
               END-IF
               MOVE FUNCTION NUMVAL(WS-FIELD-VALUE) TO I-UNIT-PRICE

      *    STOCK QUANTITY 
           MOVE "Enter Stock Quantity: " TO WS-FIELD-NAME
           PERFORM GET-NUMERIC-INPUT
               IF USER-CANCELLED
                    PERFORM CLEAR-SCREEN
                    DISPLAY "                Cancelled."
                    PERFORM MENU-MAIN
               END-IF
               MOVE FUNCTION NUMVAL(WS-FIELD-VALUE) TO I-STOCK

      *    CONTINUATION
           DISPLAY SPACES
           DISPLAY "Add another products? (Y/N)"
           DISPLAY "Enter Choice: " WITH NO ADVANCING 
           ACCEPT CONTINUE-ANOTHER 

           IF CONTINUE-ANOTHER = 'Y' OR CONTINUE-ANOTHER = 'y'
               PERFORM SAVE-PRODUCT
               PERFORM CLEAR-SCREEN
               PERFORM PRODUCT-ADD
            ELSE 
               PERFORM SAVE-PRODUCT
               DISPLAY SPACE
               PERFORM MENU-MAIN
           END-IF. 
           EXIT PARAGRAPH.

      *    UPDATE PRODUCT MENU
       UPDATE-PRODUCT-MENU.
           PERFORM STOCK-DISPLAY.
           DISPLAY SPACE.
           DISPLAY "=================================================="
           DISPLAY "                  UPDATE PRODUCT"
           DISPLAY "--------------------------------------------------"
           DISPLAY "1. Delete Product"
           DISPLAY "2. Update Product Details"
           DISPLAY SPACE.
           DISPLAY "9. Return"
           DISPLAY "=================================================="
           DISPLAY "Enter your choice: " WITH NO ADVANCING
           ACCEPT P-UPDATE-CHOICE
 
           EVALUATE P-UPDATE-CHOICE
               WHEN 1 
                   PERFORM CLEAR-SCREEN
                   PERFORM DELETE-PRODUCT
               WHEN 2
                   PERFORM CLEAR-SCREEN
                   PERFORM UPDATE-PRODUCT-DETAILS
               WHEN 9 
                   PERFORM MENU-MAIN
               WHEN OTHER
                   PERFORM CLEAR-SCREEN
                   DISPLAY "                 Invalid option!"
                   PERFORM UPDATE-PRODUCT-MENU
           END-EVALUATE
           DISPLAY SPACE.
           EXIT PARAGRAPH.

      *    PRODUCT DELETE     
       DELETE-PRODUCT.
           PERFORM STOCK-DISPLAY
           MOVE "Enter Product ID to delete" TO WS-FIELD-NAME
           PERFORM GET-TEXT-INPUT
               IF USER-CANCELLED
                    PERFORM CLEAR-SCREEN
                    DISPLAY "                  Cancelled."
                    PERFORM UPDATE-PRODUCT-MENU
               ELSE 
                   MOVE WS-FIELD-VALUE TO I-PRODUCT-ID
               END-IF
      
           MOVE I-PRODUCT-ID TO P-PRODUCT-ID
           READ P-PRODUCTS-FILE
               INVALID KEY
      *    CHECKS IF THE PRODUCT EXISTS       
                    PERFORM CLEAR-SCREEN
                    DISPLAY "Product ID not found!"
                    PERFORM SHOW-VALIDATION-ERROR
               IF USER-CANCELLED
                    PERFORM CLEAR-SCREEN
                    DISPLAY "                 Delete cancelled."
                    PERFORM UPDATE-PRODUCT-MENU
               ELSE
                    PERFORM CLEAR-SCREEN
                    PERFORM DELETE-PRODUCT
               END-IF

               NOT INVALID KEY
                   DISPLAY "Product found: " P-PRODUCT-NAME
                   DISPLAY "Delete (Y), else cancel: " WITH NO ADVANCING
                   ACCEPT CONTINUE-ANOTHER
                   
                   IF CONTINUE-ANOTHER = "Y" OR CONTINUE-ANOTHER = "y"
                      DELETE P-PRODUCTS-FILE
                      PERFORM CLEAR-SCREEN
                      PERFORM STOCK-DISPLAY
                      DISPLAY "     Product deleted successfully!"

                         DISPLAY "Delete another products? (Y/N)"
                         DISPLAY "Enter Choice: " WITH NO ADVANCING 
                         ACCEPT CONTINUE-ANOTHER 
   
                     IF CONTINUE-ANOTHER = 'Y' OR CONTINUE-ANOTHER = 'y'
                         PERFORM CLEAR-SCREEN
                         PERFORM DELETE-PRODUCT
                     ELSE 
                        PERFORM CLEAR-SCREEN 
                        PERFORM UPDATE-PRODUCT-MENU
                     END-IF                       
                  ELSE
                       PERFORM CLEAR-SCREEN
                       DISPLAY "                 Delete cancelled."
                       PERFORM UPDATE-PRODUCT-MENU
                   END-IF
           END-READ.
  
      *    PRODUCT UPDATE
       UPDATE-PRODUCT-DETAILS.           
           PERFORM SELECT-PRODUCT.
           IF USER-CANCELLED
               PERFORM CLEAR-SCREEN
               DISPLAY "                 Update cancelled."
               PERFORM UPDATE-PRODUCT-MENU
           END-IF

      *    DISPLAYS PRODUCT DETAILS    
           DISPLAY SPACES
           DISPLAY "==========CURRENT PRODUCT DETAILS=========="
           PERFORM INITIALIZATION
           DISPLAY "Product ID    : " FUNCTION TRIM(P-PRODUCT-ID)
           DISPLAY "Name          : " FUNCTION TRIM(P-PRODUCT-NAME)
           DISPLAY "Cost Per Unit : " FUNCTION TRIM(DF-PCOST-PER-UNIT)
           DISPLAY "Unit Price    : " FUNCTION TRIM(DF-PUNIT-PRICE)
           DISPLAY "Stock         : " FUNCTION TRIM(DF-PSTOCK)
           DISPLAY "==========================================="
           DISPLAY SPACES
           
      *    PRODUCT UPDATE INPUTS
           DISPLAY "Enter new Product Name (empty to skip): "
           WITH NO ADVANCING
           ACCEPT I-PRODUCT-NAME
      *    CHECKS IF INPUT IS EMPTY, RETAINS IF SO     
           IF FUNCTION STORED-CHAR-LENGTH(I-PRODUCT-NAME) > 2
               MOVE I-PRODUCT-NAME TO P-PRODUCT-NAME
           END-IF

           DISPLAY "Enter new Cost Per Unit (empty to skip): "
           WITH NO ADVANCING
           ACCEPT I-COST-PER-UNI
           IF FUNCTION NUMVAL(I-COST-PER-UNI) > 0
               MOVE I-COST-PER-UNI TO P-COST-PER-UNIT
           END-IF
           
           DISPLAY "Enter new Unit Price (empty to skip): "
           WITH NO ADVANCING
           ACCEPT I-UNIT-PRICE
           IF FUNCTION NUMVAL(I-UNIT-PRICE) > 0
               MOVE I-UNIT-PRICE TO P-UNIT-PRICE
           END-IF
 
           DISPLAY "Enter new Stock quantity (empty to skip): "
           WITH NO ADVANCING
           ACCEPT I-STOCK
           IF FUNCTION NUMVAL(I-STOCK) > 0
               MOVE I-STOCK TO P-STOCK
           END-IF

      *    DISPLAYS UPDATED PRODUCT DATA
           REWRITE P-PRODUCTS-RECORD
               INVALID KEY
                   DISPLAY "Error updating product!"
               NOT INVALID KEY
                   DISPLAY SPACES
                   PERFORM INITIALIZATION
                   DISPLAY "==============UPDATED DETAILS=============="
           DISPLAY "Name          : " FUNCTION TRIM(P-PRODUCT-NAME)
           DISPLAY "Cost Per Unit : " FUNCTION TRIM(DF-PCOST-PER-UNIT)
           DISPLAY "Unit Price    : " FUNCTION TRIM(DF-PUNIT-PRICE)
           DISPLAY "Stock         : " FUNCTION TRIM(DF-PSTOCK)
                   DISPLAY "==========================================="
                   DISPLAY SPACES
           END-REWRITE

           DISPLAY "Update another products? (Y/N)"
           DISPLAY "Enter Choice: " WITH NO ADVANCING 
           ACCEPT CONTINUE-ANOTHER 

           IF CONTINUE-ANOTHER = 'Y' OR CONTINUE-ANOTHER = 'y'
                PERFORM CLEAR-SCREEN
                PERFORM UPDATE-PRODUCT-DETAILS
           ELSE 
               PERFORM CLEAR-SCREEN 
               PERFORM UPDATE-PRODUCT-MENU
           END-IF.

      *    RECORD SALE
       RECORD-SALES.
           PERFORM DISPLAY-DASHBOARD
           DISPLAY "=================================================="
           DISPLAY "                   RECORD SALES"
           DISPLAY "=================================================="

           PERFORM SELECT-PRODUCT.
           IF USER-CANCELLED
               PERFORM CLEAR-SCREEN
               DISPLAY "                   Cancelled."
               PERFORM MENU-MAIN
           END-IF

           PERFORM INITIALIZATION
           DISPLAY SPACE
           DISPLAY "Product ID         : " P-PRODUCT-ID
           DISPLAY "Product Name       : " P-PRODUCT-NAME
           DISPLAY "Available Stock    : " FUNCTION TRIM(DF-PSTOCK)
           DISPLAY "Unit Price         : " FUNCTION TRIM(DF-PUNIT-PRICE)
           DISPLAY SPACE
           DISPLAY "Enter Sold Units: " WITH NO ADVANCING
           ACCEPT I-SOLD-UNITS

      *    CHECKS IF INPUT IS EMPTY OR ZERO
           IF I-SOLD-UNITS = SPACES OR I-SOLD-UNITS = ZERO OR           -
           I-SOLD-UNITS =" " 
                    PERFORM CLEAR-SCREEN
                    DISPLAY "Invalid quantity entered!"
                    PERFORM SHOW-VALIDATION-ERROR
               IF USER-CANCELLED
                    PERFORM CLEAR-SCREEN
                    DISPLAY "                Cancelled."
                    PERFORM MENU-MAIN
               ELSE
                    PERFORM CLEAR-SCREEN
                    PERFORM RECORD-SALES
               END-IF
           END-IF

      *    CHECKS IF STOCK IS INSUFFICIENT
           IF I-SOLD-UNITS > P-STOCK
               PERFORM CLEAR-SCREEN
               PERFORM INITIALIZATION
               DISPLAY "Insufficient stock! Available: " DF-PSTOCK
               DISPLAY " "
               PERFORM SHOW-VALIDATION-ERROR
               IF USER-CANCELLED
                    PERFORM CLEAR-SCREEN
                    DISPLAY "                Sale cancelled."
                    PERFORM MENU-MAIN
               ELSE
                    PERFORM CLEAR-SCREEN
                    PERFORM RECORD-SALES
               END-IF
           END-IF

      *    CALCULATION
      *    SALES RECORD
           COMPUTE CF-SALE-AMOUNT = I-SOLD-UNITS * P-UNIT-PRICE
           COMPUTE CF-COST-AMOUNT = I-SOLD-UNITS * P-COST-PER-UNIT
           COMPUTE CF-PROFIT-AMOUNT = CF-SALE-AMOUNT - CF-COST-AMOUNT

      *    PRODUCT STOCK
           COMPUTE P-STOCK = P-STOCK - I-SOLD-UNITS
           REWRITE P-PRODUCTS-RECORD
      
      *    MOVE TO SALES DATABASE
           MOVE P-PRODUCT-ID TO S-PRODUCT-ID
           MOVE P-PRODUCT-NAME TO S-PRODUCT-NAME
           MOVE I-SOLD-UNITS TO S-SOLD-UNITS
           MOVE P-UNIT-PRICE TO S-UNIT-PRICE
           MOVE CF-SALE-AMOUNT TO S-TOTAL-AMOUNT
           MOVE CF-COST-AMOUNT TO S-COST-OF-GOODS
           MOVE CF-PROFIT-AMOUNT TO S-PROFIT
           MOVE DATE-DISPLAY TO S-SALE-DATE

      *    APPEND SALES RECORD
           CLOSE S-SALES-FILE
           OPEN EXTEND S-SALES-FILE
           WRITE SALES-RECORD
           IF NOT SALES-OK
               PERFORM CLEAR-SCREEN
               DISPLAY "  Error recording sale! Status: " S-SALES-STATUS
               PERFORM RECORD-SALES
           ELSE
               DISPLAY "           Sale recorded successfully!"
               MOVE CF-SALE-AMOUNT TO DF-DISP-AMOUNT
               DISPLAY "Total Sale Amount  :  "                         -
               FUNCTION TRIM(DF-DISP-AMOUNT)
               MOVE CF-PROFIT-AMOUNT TO DF-DISP-AMOUNT
               DISPLAY "Profit             :  "                         - 
               FUNCTION TRIM(DF-DISP-AMOUNT)
               MOVE P-STOCK TO DF-PSTOCK
               DISPLAY "Remaining Stock    : " FUNCTION TRIM(DF-PSTOCK)
           END-IF
           CLOSE S-SALES-FILE

           DISPLAY " "
           DISPLAY "Enter another sale? (Y/N)"
           DISPLAY "Enter Choice: " WITH NO ADVANCING 
           ACCEPT CONTINUE-SALE 

            IF CONTINUE-SALE = 'Y' OR CONTINUE-SALE = 'y'
                PERFORM CLEAR-SCREEN
                PERFORM RECORD-SALES
            END-IF
           PERFORM CLEAR-SCREEN
           PERFORM MENU-MAIN.
             
      *    SALES RECORD      
       INCOME-STATEMENT.
           DISPLAY "=================================================="
           DISPLAY "                 INCOME STATEMENT"
           DISPLAY "=================================================="

           MOVE ZERO TO DT-TOTAL-REVENUE
           MOVE ZERO TO DT-TOTAL-PROFIT
           MOVE ZERO TO DT-TOTAL-QTY-SOLD

           OPEN INPUT S-SALES-FILE

           DISPLAY "SALES DETAILS:"
           DISPLAY "ID    NAME                  QTY           REVENUE"
           DISPLAY "      PROFIT"
           DISPLAY "--------------------------------------------------"
 
      *    CALCULATION OF TOTAL REVENUE AND PROFIT
           PERFORM UNTIL SALES-EOF
               READ S-SALES-FILE
                   AT END
                       SET SALES-EOF TO TRUE
                   NOT AT END
                       ADD S-TOTAL-AMOUNT TO DT-TOTAL-REVENUE
                       ADD S-PROFIT TO DT-TOTAL-PROFIT
                       ADD S-SOLD-UNITS TO DT-TOTAL-QTY-SOLD

                       MOVE S-SOLD-UNITS TO DF-DISP-QTY
                       MOVE S-TOTAL-AMOUNT TO DF-DISP-AMOUNT
                       MOVE S-PROFIT TO DF-S-PROFIT
                       
                       DISPLAY S-PRODUCT-ID " "
                               S-PRODUCT-NAME(1:15) " " 
                               DF-DISP-QTY " " 
                               DF-DISP-AMOUNT
                       DISPLAY "      " " " DF-S-PROFIT
               END-READ
           END-PERFORM

           DISPLAY "--------------------------------------------------"
           PERFORM INITIALIZATION

           DISPLAY "Total Quantity Sold: " DF-DISP-QTY
           DISPLAY "Total Revenue: " DF-DISP-AMOUNT
           DISPLAY "Total Profit: " DF-DISP-AMOUNT

      *    CONVERTION TO PERCENTAGE
           IF DT-TOTAL-REVENUE > ZERO
               COMPUTE DT-PROFIT-MARGIN =
                   (DT-TOTAL-PROFIT / DT-TOTAL-REVENUE) * 100
               MOVE DT-PROFIT-MARGIN TO DF-DISP-PERCENTAGE
               DISPLAY "Profit Margin: " DF-DISP-PERCENTAGE "%"
           END-IF
           CLOSE S-SALES-FILE.

           DISPLAY "==================================================".

      *    VIEW PRODUCT DETAILS
       VIEW-PRODUCT-DETAILS-MENU. 
           DISPLAY "=================================================="
           DISPLAY "              VIEW PRODUCT DETAILS"
           DISPLAY "=================================================="
           DISPLAY "1. View single product details"
           DISPLAY "2. View all products details"
           DISPLAY " "
           DISPLAY "9. Return to main menu"
           DISPLAY "=================================================="
           DISPLAY "Enter your choice: " WITH NO ADVANCING
           ACCEPT IS-CHOICE

           EVALUATE IS-CHOICE
               WHEN 1
                   PERFORM CLEAR-SCREEN
                   PERFORM VIEW-SINGLE-PRODUCT
               WHEN 2
                   PERFORM CLEAR-SCREEN
                   PERFORM VIEW-ALL-PRODUCTS
               WHEN 9
                   PERFORM CLEAR-SCREEN
                   PERFORM MENU-MAIN
               WHEN OTHER
                   PERFORM CLEAR-SCREEN
                   DISPLAY "Invalid option!"
                   PERFORM VIEW-PRODUCT-DETAILS-MENU
           END-EVALUATE.

      *    VIEW SINGLE PRODUCT DETAILS
       VIEW-SINGLE-PRODUCT.
           PERFORM SELECT-PRODUCT
           IF USER-CANCELLED
               PERFORM CLEAR-SCREEN
               DISPLAY "                 Cancelled."
               PERFORM VIEW-PRODUCT-DETAILS-MENU
           END-IF

           PERFORM CALCULATE-DASHBOARD
           PERFORM INITIALIZATION
           PERFORM CALCULATE-PRODUCT-REVENUE

           DISPLAY "=================================================="
           DISPLAY "           DETAILED PRODUCT INFORMATION"
           DISPLAY "=================================================="
           DISPLAY " "
           DISPLAY "PRODUCT INFORMATION:"
           DISPLAY "--------------------------------------------------"
           PERFORM INITIALIZATION
           
           DISPLAY "Product ID         : " P-PRODUCT-ID
           DISPLAY "Product Name       : " P-PRODUCT-NAME
           DISPLAY "Cost Per Unit      : " DF-PCOST-PER-UNIT
           DISPLAY "Unit Price         : " DF-PUNIT-PRICE
           DISPLAY "Current Stock      : " DF-PSTOCK

      *    DATE DISPLAY  
           MOVE P-DATE-ADDED(1:2) TO CD-MONTH
           MOVE P-DATE-ADDED(3:2) TO CD-DAY
           MOVE P-DATE-ADDED(5:4) TO CD-YEAR
           DISPLAY "Date Added         : " 
                   CD-MONTH "/" CD-DAY "/" CD-YEAR
           
      *    CALCULATION AND DISPLAY OF PRODUCT DETAIL 
           DISPLAY " "
           DISPLAY "SALES PERFORMANCE:"
           DISPLAY "--------------------------------------------------"
           MOVE PR-TIMES-SOLD TO DF-DISP-QTY
           DISPLAY "Times Sold         : " FUNCTION TRIM(DF-DISP-QTY)
    
           MOVE PR-TOTAL-SOLD TO DF-DISP-QTY
           DISPLAY "Total Units Sold   : " FUNCTION TRIM(DF-DISP-QTY)
           
           MOVE PR-TOTAL-REVENUE TO DF-DISP-AMOUNT
           DISPLAY "Total Revenue      : " 
                   FUNCTION TRIM(DF-DISP-AMOUNT)
           
           MOVE PR-TOTAL-PROFIT TO DF-DISP-AMOUNT
           DISPLAY "Total Profit       : " 
                   FUNCTION TRIM(DF-DISP-AMOUNT)
           
           IF PR-TOTAL-REVENUE > ZERO
               COMPUTE DT-PROFIT-MARGIN = 
                   (PR-TOTAL-PROFIT / PR-TOTAL-REVENUE) * 100
               MOVE DT-PROFIT-MARGIN TO DF-DISP-PERCENTAGE
               DISPLAY "Profit Margin      : " DF-DISP-PERCENTAGE "%"
           END-IF
           
           DISPLAY "=================================================="
           DISPLAY " "
           DISPLAY "Press any key to continue..."
           ACCEPT OMITTED
           PERFORM CLEAR-SCREEN
           PERFORM VIEW-PRODUCT-DETAILS-MENU.
 
      *    VIEW ALL PRODUCT DETAILS*    VIEW ALL PRODUCT DETAILS
       VIEW-ALL-PRODUCTS.
           PERFORM CALCULATE-DASHBOARD
           PERFORM INITIALIZATION
           PERFORM CALCULATE-PRODUCT-REVENUE
           
           DISPLAY "=================================================="
           DISPLAY "          ALL PRODUCTS DETAILED REPORT"
           DISPLAY "=================================================="
           DISPLAY " "
       
      *   INITIALIZE PRODUCT FILE READING FROM THE START
           MOVE LOW-VALUES TO P-PRODUCT-ID         
           START P-PRODUCTS-FILE KEY IS GREATER THAN P-PRODUCT-ID
       
      *   LOOP THROUGH ALL PRODUCTS IN THE DATABASE
           PERFORM UNTIL PRODUCTS-EOF OR P-PRODUCTS-STATUS NOT = "00"
               READ P-PRODUCTS-FILE NEXT RECORD
                   AT END 
                       SET PRODUCTS-EOF TO TRUE
                   NOT AT END
      *               CALCULATE SALES METRICS FOR CURRENT PRODUCT
                       PERFORM CALCULATE-PRODUCT-REVENUE
                       
      *               FORMAT AND DISPLAY PRODUCT INFORMATION
                    DISPLAY "------------------------------------------"
                       
      *               DISPLAY PRODUCT ID AND NAME
                       DISPLAY "ID: " P-PRODUCT-ID 
                               " | " P-PRODUCT-NAME
                       
      *               FORMAT AND DISPLAY DATE ADDED WITH CURRENT STOCK
                       MOVE P-DATE-ADDED(1:2) TO CD-MONTH
                       MOVE P-DATE-ADDED(3:2) TO CD-DAY
                       MOVE P-DATE-ADDED(5:4) TO CD-YEAR
                       DISPLAY "Added: " CD-MONTH "/" CD-DAY "/" CD-YEAR
                               " | Stock: " FUNCTION TRIM(DF-PSTOCK)
                       
      *               DISPLAY COST AND SELLING PRICE
                       DISPLAY "Cost: " FUNCTION TRIM(DF-PCOST-PER-UNIT)
                               " | Price: "FUNCTION TRIM(DF-PUNIT-PRICE)
       
      *               FORMAT SALES QUANTITIES AND REVENUE
                       MOVE PR-TOTAL-SOLD TO DF-DISP-QTY
                       MOVE PR-TOTAL-REVENUE TO DF-DISP-AMOUNT
                       DISPLAY "Sold: " FUNCTION TRIM(DF-DISP-QTY)
                               " units | Revenue: " 
                               FUNCTION TRIM(DF-DISP-AMOUNT)
                       
      *               DISPLAY PROFIT INFORMATION
                       MOVE PR-TOTAL-PROFIT TO DF-DISP-AMOUNT
                       DISPLAY "Profit: " FUNCTION TRIM(DF-DISP-AMOUNT)
               END-READ
           END-PERFORM

           DISPLAY "=================================================="
           DISPLAY " "
           DISPLAY "Press any key to continue..."
           ACCEPT OMITTED

           PERFORM CLEAR-SCREEN
           PERFORM VIEW-PRODUCT-DETAILS-MENU.

      *    CALCULATE PRODUCT REVENUE
       CALCULATE-PRODUCT-REVENUE.
      *    TO RESET VALUES
           MOVE ZERO TO PR-TOTAL-REVENUE
           MOVE ZERO TO PR-TOTAL-PROFIT
           MOVE ZERO TO PR-TOTAL-SOLD
           MOVE ZERO TO PR-TIMES-SOLD

           CLOSE S-SALES-FILE
           OPEN INPUT S-SALES-FILE

      *    CALCULATES VALUES FOR PRODUCT REVENUE.
           PERFORM UNTIL SALES-EOF
               READ S-SALES-FILE
                   AT END
                       SET SALES-EOF TO TRUE
                   NOT AT END
                       IF S-PRODUCT-ID = P-PRODUCT-ID
                           ADD S-TOTAL-AMOUNT TO PR-TOTAL-REVENUE
                           ADD S-PROFIT TO PR-TOTAL-PROFIT
                           ADD S-SOLD-UNITS TO PR-TOTAL-SOLD
                           ADD 1 TO PR-TIMES-SOLD
                       END-IF
               END-READ
           END-PERFORM

           CLOSE S-SALES-FILE.

      *    DISPLAY DASHBOARD - STOCK, INITIALIZATION, TERMINATION
       DISPLAY-DASHBOARD.
           PERFORM CALCULATE-DASHBOARD
           PERFORM INITIALIZATION
           PERFORM CALCULATE-PRODUCT-REVENUE

           DISPLAY "=================================================="
           DISPLAY "                DASHBOARD SUMMARY"
           DISPLAY "=================================================="
           DISPLAY "Total Products: " FUNCTION TRIM(DF-DISP-QTY)
           DISPLAY "Total Stock Units: " FUNCTION TRIM(DF-DISP-QTY)
           DISPLAY "Total Revenue:  " FUNCTION TRIM(DF-DISP-AMOUNT)
           DISPLAY "Total Profit:  " FUNCTION TRIM(DF-DISP-AMOUNT)
           DISPLAY "Total Units Sold: " FUNCTION TRIM(DF-DISP-QTY)

           IF DT-TOTAL-REVENUE > ZERO
               COMPUTE DT-PROFIT-MARGIN = 
                   (DT-TOTAL-PROFIT / DT-TOTAL-REVENUE) * 100
               MOVE DT-PROFIT-MARGIN TO DF-DISP-PERCENTAGE
               DISPLAY "Profit Margin: " DF-DISP-PERCENTAGE "%"
           END-IF.
           
      *    STOCK DISPLAY     
       STOCK-DISPLAY.
           DISPLAY "=================================================="
           DISPLAY "               CURRENT STOCK LEVELS"
           DISPLAY "=================================================="
           DISPLAY "ID         NAME              STOCK     ADDED ON"
           DISPLAY "--------------------------------------------------"

           MOVE LOW-VALUES TO P-PRODUCT-ID
           START P-PRODUCTS-FILE KEY IS GREATER THAN P-PRODUCT-ID
           PERFORM UNTIL PRODUCTS-EOF OR P-PRODUCTS-STATUS NOT = "00"
               READ P-PRODUCTS-FILE NEXT RECORD
                   AT END 
                       SET PRODUCTS-EOF TO TRUE
                   NOT AT END
                       MOVE P-STOCK TO DF-DISP-QTY

                       MOVE P-DATE-ADDED(1:2) TO CD-MONTH
                       MOVE P-DATE-ADDED(3:2) TO CD-DAY
                       MOVE P-DATE-ADDED(5:4) TO CD-YEAR

                       DISPLAY 
                           P-PRODUCT-ID " "
                           P-PRODUCT-NAME(1:15) " "
                           DF-DISP-QTY "     "
                           CD-MONTH "/" CD-DAY "/" CD-YEAR
               END-READ
           END-PERFORM
           DISPLAY "--------------------------------------------------"
           DISPLAY SPACE.

       CALCULATE-DASHBOARD.
           MOVE ZERO TO DT-TOTAL-PRODUCTS
           MOVE ZERO TO DT-TOTAL-STOCK
           MOVE ZERO TO DT-TOTAL-REVENUE
           MOVE ZERO TO DT-TOTAL-PROFIT
           MOVE ZERO TO DT-TOTAL-QTY-SOLD
           
           MOVE LOW-VALUES TO P-PRODUCT-ID
           START P-PRODUCTS-FILE KEY IS GREATER THAN P-PRODUCT-ID
           PERFORM UNTIL PRODUCTS-EOF OR P-PRODUCTS-STATUS NOT = "00"
               READ P-PRODUCTS-FILE NEXT RECORD
                   AT END SET PRODUCTS-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO DT-TOTAL-PRODUCTS
                       ADD P-STOCK TO DT-TOTAL-STOCK
               END-READ
           END-PERFORM
           
      *    DISPLAY SALES RECORD
           CLOSE S-SALES-FILE
           OPEN INPUT S-SALES-FILE
           PERFORM UNTIL SALES-EOF
               READ S-SALES-FILE
                   AT END SET SALES-EOF TO TRUE
                   NOT AT END
                       ADD S-TOTAL-AMOUNT TO DT-TOTAL-REVENUE
                       ADD S-PROFIT TO DT-TOTAL-PROFIT
                       ADD S-SOLD-UNITS TO DT-TOTAL-QTY-SOLD
               END-READ
           END-PERFORM
           CLOSE S-SALES-FILE.
    
      *    INITIALIZATION
       INITIALIZATION.
      *    MOVES INPUT TO DASHBOARD AND DISPLAY

           MOVE P-COST-PER-UNIT TO DF-PCOST-PER-UNIT
           MOVE P-STOCK TO DF-PSTOCK
           MOVE P-UNIT-PRICE TO DF-PUNIT-PRICE
           
           MOVE DT-TOTAL-PRODUCTS TO DF-DISP-QTY
           MOVE DT-TOTAL-STOCK TO DF-DISP-QTY
           MOVE DT-TOTAL-REVENUE TO DF-DISP-AMOUNT
           MOVE DT-TOTAL-PROFIT TO DF-DISP-AMOUNT
           MOVE DT-TOTAL-QTY-SOLD TO DF-DISP-QTY

           ACCEPT CURRENT-DATE FROM DATE YYYYMMDD
           MOVE CURRENT-DATE(5:2) TO DATE-DISPLAY(1:2)
           MOVE "/" TO DATE-DISPLAY(3:1)
           MOVE CURRENT-DATE(7:2) TO DATE-DISPLAY(4:2)
           MOVE "/" TO DATE-DISPLAY(6:1)
           MOVE CURRENT-DATE(1:4) TO DATE-DISPLAY(7:4)
           
           OPEN I-O P-PRODUCTS-FILE
           IF NOT PRODUCTS-OK
               OPEN OUTPUT P-PRODUCTS-FILE
               CLOSE P-PRODUCTS-FILE
               OPEN I-O P-PRODUCTS-FILE
           END-IF
           
           OPEN INPUT S-SALES-FILE
           IF NOT SALES-OK
               OPEN OUTPUT S-SALES-FILE
               CLOSE S-SALES-FILE  
               OPEN INPUT S-SALES-FILE
           END-IF
           DISPLAY SPACE.

      *    DATABASE RESET
      *    SALES RESET
       SALES-RESET.
           PERFORM CLEAR-SCREEN
           PERFORM INCOME-STATEMENT
           DISPLAY SPACES 
      *    CONFIRMATION     
           DISPLAY "Reset SALES Database? This can not be undone. "     
           DISPLAY "Enter (Y) else cancel: " WITH NO ADVANCING
           ACCEPT RESET-SALES

           IF RESET-SALES = 'Y' OR RESET-SALES = 'y'
               ACCEPT WS-OS-NAME FROM ENVIRONMENT "OS"
               IF WS-OS-NAME = "Windows_NT"
                   CALL "SYSTEM" USING "del SALES.DAT"
               ELSE 
                   CALL "SYSTEM" USING "rm SALES.DAT"
               END-IF

               DISPLAY "Database have been reset sucessfully."
               PERFORM MENU-MAIN
           ELSE 
               PERFORM CLEAR-SCREEN
               DISPLAY "                  Cancelled."
               ACCEPT OMITTED
               PERFORM MENU-MAIN
           END-IF.
           EXIT PARAGRAPH.

      *    PRODUCT RESET
       PRODUCTS-RESET.
           PERFORM CLEAR-SCREEN
           PERFORM STOCK-DISPLAY
           DISPLAY SPACES
           DISPLAY "Reset PRODUCTS Database? This can not be undone. "
           DISPLAY "Enter (Y) else cancel: " WITH NO ADVANCING 
           ACCEPT RESET-PRODUCTS

           IF RESET-PRODUCTS = 'Y' OR RESET-PRODUCTS = 'y'
               ACCEPT WS-OS-NAME FROM ENVIRONMENT "OS"
               IF WS-OS-NAME = "Windows_NT"
                   CALL "SYSTEM" USING "del PRODUCTS.DAT"
               ELSE 
                   CALL "SYSTEM" USING "rm PRODUCTS.DAT"
               END-IF

               DISPLAY "Database have been reset sucessfully."
               PERFORM MENU-MAIN
           ELSE 
               PERFORM CLEAR-SCREEN
               DISPLAY "                  Cancelled."
               ACCEPT OMITTED
               PERFORM MENU-MAIN
           END-IF.
           EXIT PARAGRAPH.
       
      *    CHECKS IF INPUT IS VALID
      *    NUMERIC INPUT
       GET-NUMERIC-INPUT.
      *    MOVES INPUT TO VALIDATION FLAGS
           MOVE ALL SPACES TO WS-VALIDATION-FLAGS
           MOVE 'N' TO WS-IS-VALID
           PERFORM UNTIL VALID-INPUT OR USER-CANCELLED
               DISPLAY WS-FIELD-NAME ": " WITH NO ADVANCING
               ACCEPT WS-FIELD-VALUE

      *    CHECKS IF INPUT IS EMPTY
               IF WS-FIELD-VALUE = SPACES OR WS-FIELD-VALUE = ZERO
                   PERFORM SHOW-VALIDATION-ERROR
                   IF USER-CANCELLED EXIT PARAGRAPH END-IF
               ELSE
      *    CHECKS IF INPUT IS ZERO OR NEGATIVE
                   IF FUNCTION TEST-NUMVAL(WS-FIELD-VALUE) = 0
                      IF FUNCTION NUMVAL(WS-FIELD-VALUE) <= 0
                           DISPLAY "Value must be greater than zero."
                           PERFORM SHOW-VALIDATION-ERROR
                           IF USER-CANCELLED EXIT PARAGRAPH END-IF
                       ELSE
      *    INPUT IS VALIDATED
                           MOVE 'Y' TO WS-IS-VALID
                       END-IF

                   ELSE
                       DISPLAY "Invalid numeric value. Try again."
                       PERFORM SHOW-VALIDATION-ERROR
                       IF USER-CANCELLED EXIT PARAGRAPH END-IF
                   END-IF
               END-IF
           END-PERFORM.
    
      *    TEXT INPUT
       GET-TEXT-INPUT.
           MOVE ALL SPACES TO WS-VALIDATION-FLAGS
           MOVE 'N' TO WS-IS-VALID
           PERFORM UNTIL VALID-INPUT OR USER-CANCELLED
               DISPLAY WS-FIELD-NAME ": " WITH NO ADVANCING
               ACCEPT WS-FIELD-VALUE

               IF WS-FIELD-VALUE = SPACES
                   PERFORM SHOW-VALIDATION-ERROR
                   IF USER-CANCELLED
                       EXIT PARAGRAPH
                   END-IF
               ELSE
                   MOVE 'Y' TO WS-IS-VALID
               END-IF
           END-PERFORM.

      *    SHOW VALIDATION ERROR
       SHOW-VALIDATION-ERROR.
      *    CONTINUATION OR CANCELLATION
           DISPLAY SPACE
           DISPLAY "Invalid value. Press 'N' to cancel or any key"
           DISPLAY "to retry: " WITH NO ADVANCING
           ACCEPT WS-USER-CHOICE
          
           IF NOT USER-CANCELLED
               MOVE 'Y' TO WS-USER-CHOICE
           END-IF.
           DISPLAY SPACE.

      *    SAVE PRODUCT
       SAVE-PRODUCT.
      *    MOVES INPUT TO DATABASE VARIABLES
           MOVE I-PRODUCT-ID TO P-PRODUCT-ID
           MOVE I-PRODUCT-NAME TO P-PRODUCT-NAME
           MOVE I-COST-PER-UNI TO P-COST-PER-UNIT
           MOVE I-UNIT-PRICE TO P-UNIT-PRICE
           MOVE I-STOCK TO P-STOCK
           MOVE DATE-DISPLAY TO P-DATE-ADDED

      *    SAVES CURRENT DATE
           ACCEPT CURRENT-DATE FROM DATE YYYYMMDD
           MOVE CURRENT-DATE(5:2) TO DATE-DISPLAY(1:2)
           MOVE "/" TO DATE-DISPLAY(3:1)
           MOVE CURRENT-DATE(7:2) TO DATE-DISPLAY(4:2)
           MOVE "/" TO DATE-DISPLAY(6:1)
           MOVE CURRENT-DATE(1:4) TO DATE-DISPLAY(7:4)
           MOVE DATE-DISPLAY TO P-DATE-ADDED
         
           WRITE P-PRODUCTS-RECORD
               INVALID KEY
                   DISPLAY "Error adding product!"
      *    SAVES DATABASE VARIABLES TO DAT FILE
               NOT INVALID KEY
                   PERFORM INITIALIZATION
                   DISPLAY "Product added successfully!"
                   DISPLAY "Product ID: " P-PRODUCT-ID
                   DISPLAY "Name: " P-PRODUCT-NAME
                   DISPLAY "Cost Per Unit: " DF-PCOST-PER-UNIT
                   DISPLAY "Unit Price: " DF-PUNIT-PRICE
                   DISPLAY "Stock: " P-STOCK
           END-WRITE.
           
      *    SELECT PRODUCT     
       SELECT-PRODUCT.
      *    CHECKS IF PRODUCT EXISTS
           PERFORM STOCK-DISPLAY
           MOVE "Enter Product ID to select" TO WS-FIELD-NAME
           PERFORM GET-TEXT-INPUT
           
           IF USER-CANCELLED
               EXIT PARAGRAPH
           END-IF

           MOVE WS-FIELD-VALUE TO P-PRODUCT-ID
           READ P-PRODUCTS-FILE
               INVALID KEY
                   PERFORM CLEAR-SCREEN
                   DISPLAY "            Product ID not found!"
                   PERFORM SHOW-VALIDATION-ERROR
                   IF USER-CANCELLED
                       EXIT PARAGRAPH
                   ELSE
                       PERFORM CLEAR-SCREEN
                       PERFORM SELECT-PRODUCT
                   END-IF
           END-READ.
 
      *    CLEAR SCREEN
       CLEAR-SCREEN.
      *    FETCHES THE OS FOR PROPER SYSTEM CALL
           ACCEPT WS-OS-NAME FROM ENVIRONMENT "OS"
           IF WS-OS-NAME = "Windows_NT"
               CALL "SYSTEM" USING "cls"
           ELSE 
               CALL "SYSTEM" USING "clear"
           END-IF.

      *    TERMINATE
       PROG-TERMINATE.
      *    CLOSES OPENED FILES
           CLOSE P-PRODUCTS-FILE
           CLOSE S-SALES-FILE
           PERFORM CLEAR-SCREEN.
           DISPLAY SPACE.
           DISPLAY "          Files saved. System terminated."
           DISPLAY SPACE.
           STOP RUN.

