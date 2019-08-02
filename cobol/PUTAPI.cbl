       CBL APOST
      *----------------------------------------------------------------*
      *                                                                *
      * ENTRY POINT = POSTAPI                                          *
      *                                                                *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. POSTAPI.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *----------------------------------------------------------------*
      * Common defintions                                              *
      *----------------------------------------------------------------*

      * Error Message structure
       01  ERROR-MSG.
           03 EM-ORIGIN                PIC X(8)  VALUE SPACES.
           03 EM-CODE                  PIC S9(9) COMP-5 SYNC VALUE 0.
           03 EM-DETAIL                PIC X(1024) VALUE SPACES.

      * Copy API requester required copybook
       COPY BAQRINFO.

      * POSTAPI and Response
       01 API-REQUEST.
           COPY CSC00Q01.
       01 API_RESPONSE.
           COPY CSC00P01.
      * Structure with the API information
       01 API-INFO-OPER1.
           COPY CSC00I01.

      * Request and Response segment, used to store request and
      * response content.
       01 BAQ-REQUEST-PTR             USAGE POINTER.
       01 BAQ-REQUEST-LEN             PIC S9(9) COMP-5 SYNC.
       01 BAQ-RESPONSE-PTR            USAGE POINTER.
       01 BAQ-RESPONSE-LEN            PIC S9(9) COMP-5 SYNC.
       01 EIBRESP                     PIC X(8).
       01 EIBRESP2                    PIC X(8).
       77 COMM-STUB-PGM-NAME          PIC X(8) VALUE 'BAQCSTUB'.

      *----------------------------------------------------------------*

      ******************************************************************
      *    L I N K A G E   S E C T I O N
      ******************************************************************
       LINKAGE SECTION.
       01   PARM-BUFFER.
            05 PARM-LENGTH   PIC S9(4) COMP.
            05 PARM-DATA.
               10 numb       PIC X(6).
               10 filler     PIC X(250).
      ******************************************************************
      *    P R O C E D U R E S
      ******************************************************************
       PROCEDURE DIVISION using PARM-BUFFER.

      *----------------------------------------------------------------*
       MAINLINE SECTION.

      *----------------------------------------------------------------*
      * Common code                                                    *
      *----------------------------------------------------------------*
      * initialize working storage variables
           INITIALIZE API-REQUEST.
           INITIALIZE API_RESPONSE.
           INITIALIZE BAQ-REQUEST-INFO.
           INITIALIZE BAQ-RESPONSE-INFO.

      *---------------------------------------------------------------*
      * Set up the data for the API Requester call                    *
      *---------------------------------------------------------------*
           MOVE 1 to cscvincServiceOperatio-num in API-REQUEST
                     REQUEST-CONTAINER2-num in API-REQUEST
                     FILEA-AREA2-num in API-REQUEST
                     NUMB-num in API-REQUEST
                     NAME-num in API-REQUEST
                     NUMB-num in API-REQUEST
                     NAME-num in API-REQUEST
                     ADDRX-num in API-REQUEST
                     PHONE-num in API-REQUEST
                     DATEX-num in API-REQUEST
                     AMOUNT-num in API-REQUEST.

           MOVE numb of PARM-DATA TO numb2 IN API-REQUEST.
           MOVE LENGTH of numb2 in API-REQUEST to
               numb2-length IN API-REQUEST.

           MOVE "John" TO name2 IN API-REQUEST.
           MOVE LENGTH of name2 in API-REQUEST to
               name2-length IN API-REQUEST.

           MOVE "Apex" TO addrx2 IN API-REQUEST.
           MOVE LENGTH of addrx2 in API-REQUEST to
               addrx2-length IN API-REQUEST.

           MOVE "0065" TO phone2 IN API-REQUEST.
           MOVE LENGTH of phone2 in API-REQUEST to
               phone2-length IN API-REQUEST.

           MOVE "11 22 65" TO datex2 IN API-REQUEST.
           MOVE LENGTH of datex2 in API-REQUEST to
               datex2-length IN API-REQUEST.

           MOVE "$1000.65" TO amount2 IN API-REQUEST.
           MOVE LENGTH of amount2 in API-REQUEST to
               amount2-length IN API-REQUEST.

      *---------------------------------------------------------------*
      * Initialize API Requester PTRs & LENs                          *
      *---------------------------------------------------------------*
      * Use pointer and length to specify the location of
      *  request and response segment.
      * This procedure is general and necessary.
           SET BAQ-REQUEST-PTR TO ADDRESS OF API-REQUEST.
           MOVE LENGTH OF API-REQUEST TO BAQ-REQUEST-LEN.
           SET BAQ-RESPONSE-PTR TO ADDRESS OF API_RESPONSE.
           MOVE LENGTH OF API_RESPONSE TO BAQ-RESPONSE-LEN.

      *---------------------------------------------------------------*
      * Call the communication stub                                   *
      *---------------------------------------------------------------*
      * Call the subsystem-supplied stub code to send
      * API request to zCEE
           CALL COMM-STUB-PGM-NAME USING
                BY REFERENCE   API-INFO-OPER1
                BY REFERENCE   BAQ-REQUEST-INFO
                BY REFERENCE   BAQ-REQUEST-PTR
                BY REFERENCE   BAQ-REQUEST-LEN
                BY REFERENCE   BAQ-RESPONSE-INFO
                BY REFERENCE   BAQ-RESPONSE-PTR
                BY REFERENCE   BAQ-RESPONSE-LEN.
      * The BAQ-RETURN-CODE field in 'BAQRINFO' indicates whether this
      * API call is successful.

      * When BAQ-RETURN-CODE is 'BAQ-SUCCESS', response is
      * successfully returned and fields in RESPONSE copybook
      * can be obtained. Display the translation result.
           IF BAQ-SUCCESS THEN
              MOVE CEIBRESP of API_RESPONSE to EIBRESP
              MOVE CEIBRESP2 of API_RESPONSE to EIBRESP2
              DISPLAY "NUMB:   " numb2   of API_RESPONSE
              DISPLAY "NAME:   " name2   of API_RESPONSE
              DISPLAY "ADDRX:  " addrx2  of API_RESPONSE
              DISPLAY "PHONE:  " phone2  of API_RESPONSE
              DISPLAY "DATEX:  " datex2  of API_RESPONSE
              DISPLAY "AMOUNT: " amount2 of API_RESPONSE
              DISPLAY "EIBRESP:    " EIBRESP
              DISPLAY "EIBRESP2:   " EIBRESP2
              DISPLAY "HTTP CODE:  " BAQ-STATUS-CODE

      * Otherwise, some error happened in API, z/OS Connect EE server
      * or communication stub. 'BAQ-STATUS-CODE' and
      * 'BAQ-STATUS-MESSAGE' contain the detailed information
      *  of this error.
           ELSE
              DISPLAY "Error code: " BAQ-STATUS-CODE
              DISPLAY "Error msg:" BAQ-STATUS-MESSAGE
              MOVE BAQ-STATUS-CODE TO EM-CODE
              MOVE BAQ-STATUS-MESSAGE TO EM-DETAIL
              EVALUATE TRUE
      * When error happens in API, BAQ-RETURN-CODE is BAQ-ERROR-IN-API.
      * BAQ-STATUS-CODE is the HTTP response code of API.
                 WHEN BAQ-ERROR-IN-API
                   MOVE 'API' TO EM-ORIGIN
      * When error happens in server, BAQ-RETURN-CODE is
      * BAQ-ERROR-IN-ZCEE
      * BAQ-STATUS-CODE is the HTTP response code of
      * z/OS Connect EE server.
                 WHEN BAQ-ERROR-IN-ZCEE
                   MOVE 'ZCEE' TO EM-ORIGIN
      * When error happens in communication stub, BAQ-RETURN-CODE is
      * BAQ-ERROR-IN-STUB, BAQ-STATUS-CODE is the error code of STUB.
                 WHEN BAQ-ERROR-IN-STUB
                   MOVE 'STUB' TO EM-ORIGIN
              END-EVALUATE
              DISPLAY "Error origin:" EM-ORIGIN
           END-IF.

       MAINLINE-EXIT.
           GOBACK.
