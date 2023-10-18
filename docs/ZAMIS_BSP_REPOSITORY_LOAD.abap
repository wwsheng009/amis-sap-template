*&---------------------------------------------------------------------*
*& Report  UI5_REPOSITORY_LOAD
*&
*&---------------------------------------------------------------------*
*&
*& This report implements the up- and download of a SAPUI5 application
*& into an UI5 Repository.
*&
*& Furthermore it is possible to delete a UI5 Repository
*&
*&---------------------------------------------------------------------*

REPORT zamis_bsp_repository_load LINE-SIZE 255.

TYPE-POOLS abap.

************************************************************************
************************************************************************
*                                                                      *
*                UI5 Repositor Load - Local Helper Classes             *
*                                                                      *
************************************************************************
************************************************************************

************************************************************************
* Class LCL_FUNCTION
*
* provides some helper functions.
************************************************************************
CLASS lcl_function DEFINITION.
  PUBLIC SECTION.

    TYPES:          x255_table                   TYPE STANDARD TABLE OF raw255.
    CLASS-METHODS:  adjust_line_endings          IMPORTING iv_string        TYPE string
                                                 RETURNING VALUE(rv_string) TYPE string,
      max                          IMPORTING a             TYPE i DEFAULT -999999
                                             b             TYPE i DEFAULT -999999
                                             c             TYPE i DEFAULT -999999
                                             d             TYPE i DEFAULT -999999
                                             e             TYPE i DEFAULT -999999
                                             f             TYPE i DEFAULT -999999
                                   RETURNING VALUE(rv_max) TYPE i,
      text_matches_pattern         IMPORTING iv_text                        TYPE string
                                             iv_pattern_list                TYPE string_table
                                   RETURNING VALUE(rv_text_matches_pattern) TYPE abap_bool,
      xstring2xtable               IMPORTING iv_xstring TYPE xstring
                                   EXPORTING ev_xtable  TYPE x255_table
                                             ev_size    TYPE int4.

ENDCLASS.                    "lcl_function DEFINITION
*----------------------------------------------------------------------*
*       CLASS abap_unit_test2 DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS abap_unit_test2 DEFINITION FOR TESTING.
  PUBLIC SECTION.
*    DATA lcl_class TYPE REF TO lcl_function.
    METHODS: run FOR TESTING.
ENDCLASS.                    "ABAP_UNIT_TEST DEFINITION
*----------------------------------------------------------------------*
*       CLASS abap_unit_test IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS abap_unit_test2 IMPLEMENTATION.

  METHOD run.
    DATA new_string TYPE string.
    DATA old_string TYPE string VALUE 'Here is a text representing a file content'.
    DATA max TYPE i.

    new_string = lcl_function=>adjust_line_endings( iv_string = old_string ).
    cl_aunit_assert=>assert_equals( exp = old_string act = new_string ).
    max = lcl_function=>max( a = 1 b = 2 c = 3 d = 4 e = 5 f = 6 ).
    cl_aunit_assert=>assert_equals( exp = 6 act = max msg = 'Maximum value not found' ).
    DATA matched TYPE abap_bool.
    DATA strable TYPE string_table.
    APPEND 'He' TO strable.
    APPEND 'Hi' TO strable.
    matched = lcl_function=>text_matches_pattern( iv_text = 'Here comes the sun' iv_pattern_list = strable ).
    cl_aunit_assert=>assert_equals( exp = abap_true act = matched msg = 'Match not found' ).
    CLEAR strable.
    APPEND 'Xx' TO strable.
    APPEND 'Yy' TO strable.
    matched = lcl_function=>text_matches_pattern( iv_text = 'Die Quadrate der Umlaufzeiten verhalten sich wie die dritten Potenzen der mittleren Entfernung von der Sonne' iv_pattern_list = strable ).
    cl_aunit_assert=>assert_equals( exp = abap_false act = matched msg = 'Match found' ).
    DATA xstr TYPE xstring.
    DATA xtab TYPE STANDARD TABLE OF raw255.
    DATA size TYPE int4.
    CALL METHOD lcl_function=>xstring2xtable( EXPORTING iv_xstring = xstr IMPORTING ev_xtable = xtab ev_size = size ).
    cl_aunit_assert=>assert_equals( exp = '' act = '' msg = 'Convertion failed').
  ENDMETHOD.                    "run
ENDCLASS.                    "abap_unit_test IMPLEMENTATION
************************************************************************
CLASS lcl_function IMPLEMENTATION.

  METHOD adjust_line_endings.

    DATA: string             TYPE string,
          regular_expression TYPE string,
          replace_with       TYPE string.
    string = iv_string.
    regular_expression = '\r\n|\n\r|\n|\r'.
    replace_with = '\r\n'.
    REPLACE ALL OCCURRENCES OF REGEX regular_expression IN string WITH replace_with.

    rv_string = string.

  ENDMETHOD.                    "adjust_line_endings

  METHOD max.
    DATA: max TYPE i.
    max = a.
    IF ( b > a ). max = b . ENDIF.
    IF ( c > max ). max = c . ENDIF.
    IF ( d > max ). max = d . ENDIF.
    IF ( e > max ). max = e . ENDIF.
    IF ( f > max ). max = f . ENDIF.
    rv_max = max.
  ENDMETHOD.                    "max

  METHOD text_matches_pattern.

*   Initialize
    rv_text_matches_pattern = abap_false.

*   Check if string matches a pattern of the list passed on entry
    DATA: pattern                  TYPE string,
          regular_expression_check TYPE abap_bool,
          match_count              TYPE i.
    LOOP AT iv_pattern_list INTO pattern.

*     Skip empty lines
      IF strlen( pattern ) = 0. CONTINUE. ENDIF.

*     Determine if pattern to be treated as a regular expression or a substring
      DATA: first_char       TYPE c, last_char TYPE c, last_char_offset TYPE i.
      last_char_offset = strlen( pattern ) - 1.
      first_char = pattern(1).
      last_char = pattern+last_char_offset(1).
      DATA: is_regular_expression TYPE abap_bool. is_regular_expression = abap_false.
      IF first_char = '^' AND last_char = '$'. is_regular_expression = abap_true. ENDIF.

*     Check
      IF is_regular_expression = abap_true.
        TRY.
            FIND REGEX pattern IN iv_text IGNORING CASE MATCH COUNT match_count.
          CATCH cx_root.
        ENDTRY.
      ELSE.
        FIND pattern IN iv_text IGNORING CASE MATCH COUNT match_count.
      ENDIF.
      IF match_count > 0. rv_text_matches_pattern = abap_true. RETURN. ENDIF.
    ENDLOOP.

  ENDMETHOD.                    "text_matches_pattern

* Converts xstring into table of xstrings
  METHOD xstring2xtable.

*   Calculate size
    IF ev_size IS SUPPLIED.
      ev_size = xstrlen( iv_xstring ).
    ENDIF.

*   Split xstring into lines
    DATA: xline   TYPE x255,
          xstring TYPE xstring.
    FREE ev_xtable.
    xstring = iv_xstring.
    WHILE xstring IS NOT INITIAL.
      xline = xstring.
      APPEND xline TO ev_xtable.
      SHIFT xstring LEFT BY 255 PLACES IN BYTE MODE.
    ENDWHILE.

*   Clean up
    CLEAR xstring.

  ENDMETHOD.                    "xstring2table

ENDCLASS.                    "lcl_function IMPLEMENTATION


************************************************************************
* Class LCL_EXCEPTION
*
* is the exception to handle errors in this report.
************************************************************************
CLASS lcx_exception DEFINITION INHERITING FROM cx_static_check.
ENDCLASS.                    "lcx_exception DEFINITION


************************************************************************
* Class LCL_CANCELED
*
* indicates processing has been canceled by the user.
************************************************************************
CLASS lcx_canceled DEFINITION INHERITING FROM cx_dynamic_check.
ENDCLASS.                    "lcx_canceled DEFINITION


************************************************************************
* Class lcl_external_code_page
*
* supports conversion of external code page into abap code page.
************************************************************************
CLASS lcl_external_code_page DEFINITION.

  PUBLIC SECTION.

    TYPE-POOLS     abap.
    CLASS-DATA:    no_code_page                TYPE cpcodepage VALUE '0'.
    CLASS-METHODS: create                      IMPORTING iv_code_page_name            TYPE string
                                               RETURNING VALUE(rv_external_code_page) TYPE REF TO lcl_external_code_page
                                               RAISING   lcx_exception,
      for_sapgui_installation     RETURNING VALUE(rv_external_code_page) TYPE REF TO lcl_external_code_page
                                  RAISING   lcx_exception.
    METHODS:       get_abap_encoding           RETURNING VALUE(rv_abap_encoding) TYPE cpcodepage
                                               RAISING   lcx_exception,
      get_java_encoding           RETURNING VALUE(rv_java_encoding) TYPE string
                                  RAISING   lcx_exception.
    DATA:          name TYPE string READ-ONLY,
                   kind TYPE cpattrkind READ-ONLY.

ENDCLASS.                    "lcl_external_code_page DEFINITION
*----------------------------------------------------------------------*
*       CLASS abap_unit_test DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS abap_unit_test DEFINITION FOR TESTING.
  PUBLIC SECTION.
    DATA lcl_class TYPE REF TO lcl_external_code_page.
    METHODS: run FOR TESTING.
ENDCLASS.                    "ABAP_UNIT_TEST DEFINITION
*----------------------------------------------------------------------*
*       CLASS abap_unit_test IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS abap_unit_test IMPLEMENTATION.

  METHOD run.
    DATA page TYPE cpcodepage.
    TRY.
        lcl_class = lcl_external_code_page=>create( iv_code_page_name = '' ).
        cl_aunit_assert=>fail('Empty code page not excepted').
      CATCH lcx_exception.
        TRY.
            lcl_class = lcl_external_code_page=>create( iv_code_page_name = '0420' ).
          CATCH lcx_exception.
            cl_aunit_assert=>fail('Code instantiation failed').
        ENDTRY.
*        CLEAR lcl_class.
*        TRY.
*            lcl_class = lcl_external_code_page=>for_sapgui_installation( ).
*          CATCH lcx_exception.
*            cl_aunit_assert=>fail('Code instantiation fails').
*        ENDTRY.
    ENDTRY.
*    TRY.
*        page = lcl_class->get_java_encoding( ).
*        cl_aunit_assert=>assert_equals( exp = '1252' act = page msg = 'Code page (JAVA) is not 1252' ).
*      CATCH lcx_exception.
*        cl_aunit_assert=>fail('Did not get code page').
*    ENDTRY.
*    TRY.
*        page = lcl_class->get_abap_encoding( ).
*        cl_aunit_assert=>assert_equals( exp = '1160' act = page msg = 'Code page (ABAP) is not 1160' ).
*      CATCH lcx_exception.
*        cl_aunit_assert=>fail('Did not get code page').
*    ENDTRY.
  ENDMETHOD.                    "run
ENDCLASS.                    "abap_unit_test IMPLEMENTATION
************************************************************************
CLASS lcl_external_code_page IMPLEMENTATION.

  METHOD create.

*   Exception if no page name given
    IF iv_code_page_name IS INITIAL.
      RAISE EXCEPTION TYPE lcx_exception.
    ENDIF.

*   Create external code page instance and take over náme
    CREATE OBJECT rv_external_code_page.
    rv_external_code_page->name = iv_code_page_name.

*   Determine code page type from name
    DATA: name(10) TYPE c.
    name = iv_code_page_name.
    TRANSLATE name TO LOWER CASE.

    IF name(2) = 'cp'.
      rv_external_code_page->kind = 'J'.
    ELSEIF name(3) = 'iso'.
      rv_external_code_page->kind = 'H'.
    ELSEIF name(8) = 'us-ascii'.
      rv_external_code_page->kind = 'H'.
    ELSEIF name = 'utf-16be' OR
           name = 'utf-16le'.
      rv_external_code_page->kind = 'H'.
    ENDIF.

  ENDMETHOD.                    "create

  METHOD for_sapgui_installation.

*   Determine abap code page from sapgui installation
    DATA: code_page_abap TYPE abap_encoding,
          rc             TYPE i VALUE 0.
    CALL METHOD cl_gui_frontend_services=>get_saplogon_encoding
      CHANGING
        rc                            = rc
        file_encoding                 = code_page_abap
      EXCEPTIONS
        cntl_error                    = 1
        error_no_gui                  = 2
        not_supported_by_gui          = 3
        cannot_initialize_globalstate = 4
        OTHERS                        = 5.
    IF sy-subrc <> 0 OR code_page_abap = 0.
      RAISE EXCEPTION TYPE lcx_exception.
    ENDIF.

*   Determine corresponding java code page name
    DATA: java_code_page_name TYPE string,
          code_page_abap_     TYPE cpcodepage.
    code_page_abap_ = code_page_abap.
    CALL FUNCTION 'SCP_GET_JAVA_NAME'
      EXPORTING
        sap_codepage     = code_page_abap_
      IMPORTING
        name             = java_code_page_name
      EXCEPTIONS
        name_unknown     = 1
        invalid_codepage = 2
        OTHERS           = 3.
    IF sy-subrc <> 0. RAISE EXCEPTION TYPE lcx_exception. ENDIF.

*   Delegate for create
    rv_external_code_page = lcl_external_code_page=>create( iv_code_page_name = java_code_page_name ).

  ENDMETHOD.                    "create_for_abap_codepage

  METHOD get_abap_encoding.

*   Delegate ...
    IF me->kind IS NOT INITIAL.
      DATA: abap_encoding TYPE cpcodepage.
      CALL FUNCTION 'SCP_CODEPAGE_BY_EXTERNAL_NAME'
        EXPORTING
          external_name = me->name
          kind          = me->kind
        IMPORTING
          sap_codepage  = rv_abap_encoding
        EXCEPTIONS
          not_found     = 1.
    ELSE.
      "Default value for kind of code page.
      CALL FUNCTION 'SCP_CODEPAGE_BY_EXTERNAL_NAME'
        EXPORTING
          external_name = me->name
        IMPORTING
          sap_codepage  = rv_abap_encoding
        EXCEPTIONS
          not_found     = 1.
    ENDIF.
*   ... Raise exception if no abap code page found.
    IF sy-subrc <> 0. RAISE EXCEPTION TYPE lcx_exception. ENDIF.

  ENDMETHOD.                    "get_abap_encoding

  METHOD get_java_encoding.

*   Get ABAP codepage
    DATA: abap_encoding TYPE cpcodepage.
    abap_encoding = me->get_abap_encoding( ).

*   Delegate ...
    CALL FUNCTION 'SCP_GET_JAVA_NAME'
      EXPORTING
        sap_codepage     = abap_encoding
      IMPORTING
        name             = rv_java_encoding
      EXCEPTIONS
        name_unknown     = 1
        invalid_codepage = 2
        OTHERS           = 3.
    IF sy-subrc <> 0. RAISE EXCEPTION TYPE lcx_exception. ENDIF.

  ENDMETHOD.                    "get_java_encoding

ENDCLASS.                    "lcl_external_code_page


************************************************************************
* Class LCL_FILE_SYSTEM
*
* represents the local file system.
* Class offers file system related methods - e.g. to create and
* delete folders, to read and write a file.
*
* Remark:
* Method get_file_size does not work as of 10-2012
* because of a problem in cl_gui_frontend_services=>file_get_size
************************************************************************
CLASS lcl_file_system DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-DATA:    message        TYPE string,
                   path_separator TYPE string.
    CLASS-METHODS: class_constructor,
      get_instance                RETURNING VALUE(rv_self) TYPE REF TO lcl_file_system,
      read_file                   IMPORTING iv_file_path           TYPE string
                                            iv_file_is_binary      TYPE abap_bool
                                            iv_code_page_abap      TYPE cpcodepage
                                  RETURNING VALUE(rv_file_content) TYPE xstring
                                  RAISING   lcx_exception,
      write_file                  IMPORTING iv_file_path      TYPE string
                                            iv_file_is_binary TYPE abap_bool
                                            iv_code_page_abap TYPE cpcodepage DEFAULT lcl_external_code_page=>no_code_page
                                            iv_file_content   TYPE xstring
                                  RAISING   lcx_exception.
    METHODS:       create_folder               IMPORTING iv_folder_path TYPE string
                                               RAISING   lcx_exception,
      delete_file                 IMPORTING iv_file_path TYPE string
                                  RAISING   lcx_exception,
      delete_folder               IMPORTING iv_folder_path TYPE string
                                  RAISING   lcx_exception,
      directory_exists            IMPORTING iv_directory               TYPE string
                                  RETURNING VALUE(rv_directory_exists) TYPE abap_bool,
      get_file_size               IMPORTING iv_file_path        TYPE string
                                  RETURNING VALUE(rv_file_size) TYPE i,
      select_directory            IMPORTING iv_title            TYPE string
                                            iv_initial_folder   TYPE string DEFAULT ''
                                  RETURNING VALUE(rv_directory) TYPE string.
  PRIVATE SECTION.
    CLASS-DATA:    self                        TYPE REF TO lcl_file_system.

ENDCLASS.                    "LCL_FILE_SYSTEM
************************************************************************
CLASS lcl_file_system IMPLEMENTATION.

  METHOD class_constructor.
    CREATE OBJECT self.

*   Get path separator
    DATA: separator TYPE c.
    CALL METHOD cl_gui_frontend_services=>get_file_separator
      CHANGING
        file_separator       = separator
      EXCEPTIONS
        not_supported_by_gui = 1
        error_no_gui         = 2
        cntl_error           = 3
        OTHERS               = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
      path_separator = separator.
    ENDIF.

  ENDMETHOD.                    "class_constructor

  METHOD get_instance.
    rv_self = self.
  ENDMETHOD.                    "get_instance

  METHOD get_file_size.

    " Call does not work in my as of 12-2012
    CALL METHOD cl_gui_frontend_services=>file_get_size
      EXPORTING
        file_name            = iv_file_path
      IMPORTING
        file_size            = rv_file_size
      EXCEPTIONS
        file_get_size_failed = 1
        cntl_error           = 2
        error_no_gui         = 3
        not_supported_by_gui = 4
        OTHERS               = 5.
    IF sy-subrc <> 0.
      rv_file_size = -1.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ENDMETHOD.                    "get_file_size

  METHOD create_folder.

    DATA: rc TYPE i.
    CALL METHOD cl_gui_frontend_services=>directory_create
      EXPORTING
        directory                = iv_folder_path
      CHANGING
        rc                       = rc
      EXCEPTIONS
        directory_create_failed  = 1
        cntl_error               = 2
        error_no_gui             = 3
        directory_access_denied  = 4
        directory_already_exists = 5
        path_not_found           = 6
        unknown_error            = 7
        not_supported_by_gui     = 8
        wrong_parameter          = 9
        OTHERS                   = 10.

    IF sy-subrc <> 0 AND sy-subrc <> 5.
      RAISE EXCEPTION TYPE lcx_exception.
    ENDIF.

  ENDMETHOD.                    "create_folder

  METHOD delete_file.

    DATA: rc TYPE i.
    CALL METHOD cl_gui_frontend_services=>file_delete
      EXPORTING
        filename             = iv_file_path
      CHANGING
        rc                   = rc
      EXCEPTIONS
        file_delete_failed   = 1
        cntl_error           = 2
        error_no_gui         = 3
        file_not_found       = 4
        access_denied        = 5
        unknown_error        = 6
        not_supported_by_gui = 7
        wrong_parameter      = 8
        OTHERS               = 9.

    IF sy-subrc <> 0 AND sy-subrc <> 4.
      RAISE EXCEPTION TYPE lcx_exception.
    ENDIF.

  ENDMETHOD.                    "delete_file

  METHOD delete_folder.

    DATA: rc TYPE i.
    CALL METHOD cl_gui_frontend_services=>directory_delete
      EXPORTING
        directory               = iv_folder_path
      CHANGING
        rc                      = rc
      EXCEPTIONS
        directory_delete_failed = 1
        cntl_error              = 2
        error_no_gui            = 3
        path_not_found          = 4
        directory_access_denied = 5
        unknown_error           = 6
        not_supported_by_gui    = 7
        wrong_parameter         = 8
        OTHERS                  = 9.

    IF sy-subrc <> 0 AND sy-subrc <> 4.
      RAISE EXCEPTION TYPE lcx_exception.
    ENDIF.

  ENDMETHOD.                    "delete_folder

  METHOD directory_exists.

    rv_directory_exists = abap_false.

    IF iv_directory IS NOT INITIAL.
      CALL METHOD cl_gui_frontend_services=>directory_exist
        EXPORTING
          directory            = iv_directory
        RECEIVING
          result               = rv_directory_exists
        EXCEPTIONS
          cntl_error           = 1
          error_no_gui         = 2
          wrong_parameter      = 3
          not_supported_by_gui = 4
          OTHERS               = 5.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
    ENDIF.

  ENDMETHOD.                    "directory_exists

  METHOD select_directory.

    DATA: folder TYPE string.
    CALL METHOD cl_gui_frontend_services=>directory_browse
      EXPORTING
        window_title         = iv_title
        initial_folder       = iv_initial_folder
      CHANGING
        selected_folder      = folder
      EXCEPTIONS
        cntl_error           = 1
        error_no_gui         = 2
        not_supported_by_gui = 3
        OTHERS               = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    rv_directory = folder.

  ENDMETHOD.                    "select_directory

* Reads file (iv_file_path) from file system
* and returns byte sequence as an xstring (rv_file_content)
  METHOD read_file.

*   Determine file type
    DATA: file_type TYPE char10. file_type = 'ASC'.
    IF iv_file_is_binary = 'X'. file_type = 'BIN'. ENDIF.

*   Upload both text and file as binary without code page conversion
*   Delegate
    DATA: file_content_lines_bin TYPE STANDARD TABLE OF raw255, "xstring does not work here
          file_content_line_bin  TYPE raw255,
          file_length            TYPE int4.
    CALL METHOD cl_gui_frontend_services=>gui_upload
      EXPORTING
        filename                = iv_file_path
        filetype                = 'BIN'
        read_by_line            = 'X'
      IMPORTING
        filelength              = file_length
*       header                  =
      CHANGING
        data_tab                = file_content_lines_bin
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        not_supported_by_gui    = 17
        error_no_gui            = 18
        OTHERS                  = 19.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE lcx_exception.
    ENDIF.

*   Build xstring for return
    DATA:  file_content_x TYPE xstring.
    CONCATENATE LINES OF file_content_lines_bin INTO file_content_x IN BYTE MODE.
*   ... Length of xstring is that file on file system
    file_content_x = file_content_x(file_length).

*   Prepare return value
    rv_file_content = file_content_x.

  ENDMETHOD.                    "read_file

* Writes file (iv_file_path) to file system
* Content is taken from byte sequence (iv_file_content)
  METHOD write_file.

*   Determine file type
    DATA: file_type TYPE char10. file_type = 'ASC'.
    IF iv_file_is_binary = 'X'. file_type = 'BIN'. ENDIF.

*   Prepare binary data for file download
*   ... Content of text files is passed in binary form as well
    DATA: file_size              TYPE int4,
          file_content_lines_bin TYPE lcl_function=>x255_table,
          file_length            TYPE int4.
    lcl_function=>xstring2xtable( EXPORTING iv_xstring = iv_file_content
                                  IMPORTING ev_size = file_size
                                            ev_xtable = file_content_lines_bin ).
*   Delegate
    CALL METHOD cl_gui_frontend_services=>gui_download
      EXPORTING
        bin_filesize            = file_size
        filename                = iv_file_path
        filetype                = 'BIN'
      IMPORTING
        filelength              = file_length        "virus_scan_profile = '/SCET/GUI_DOWNLOAD'
      CHANGING
        data_tab                = file_content_lines_bin
      EXCEPTIONS
        file_write_error        = 1
        no_batch                = 2
        gui_refuse_filetransfer = 3
        invalid_type            = 4
        no_authority            = 5
        unknown_error           = 6
        header_not_allowed      = 7
        separator_not_allowed   = 8
        filesize_not_allowed    = 9
        header_too_long         = 10
        dp_error_create         = 11
        dp_error_send           = 12
        dp_error_write          = 13
        unknown_dp_error        = 14
        access_denied           = 15
        dp_out_of_memory        = 16
        disk_full               = 17
        dp_timeout              = 18
        file_not_found          = 19
        dataprovider_exception  = 20
        control_flush_error     = 21
        not_supported_by_gui    = 22
        error_no_gui            = 23
        OTHERS                  = 24.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE lcx_exception.
    ENDIF.

  ENDMETHOD.                    "write_file

ENDCLASS.                    "LCL_FILE_SYSTEM


************************************************************************
* Class LCL_OPERATION
*
* represents a download or upload operation to be performed.
************************************************************************
CLASS lcl_operation DEFINITION.

  PUBLIC SECTION.

    DATA:          full_path      TYPE string,
                   message        TYPE string,
                   object_is_file TYPE abap_bool,
                   object_type    TYPE string,
                   object_name    TYPE string,
                   operation      TYPE string,
                   relative_path  TYPE string.
    METHODS:       get_file_extension          RETURNING VALUE(rv_file_extension) TYPE string,
      is_binary                   RETURNING VALUE(rv_is_binary) TYPE abap_bool.
    CLASS-DATA:    create_folder           TYPE string VALUE 'CREATE FOLDER',
                   delete_folder           TYPE string VALUE 'DELETE FOLDER',
                   delete_file             TYPE string VALUE 'DELETE FILE',
                   download_file           TYPE string VALUE 'DOWNLOAD FILE',
                   ignore_file             TYPE string VALUE 'IGNORE_FILE',
                   ignore_folder           TYPE string VALUE 'IGNORE_FOLDER',
                   upload_file             TYPE string VALUE 'UPLOAD FILE',
                   object_type_none        TYPE string VALUE '',
                   object_type_binary_file TYPE string VALUE 'BINARY_FILE',
                   object_type_file        TYPE string VALUE 'FILE',
                   object_type_text_file   TYPE string VALUE 'TEXT_FILE',
                   object_type_folder      TYPE string VALUE 'FOLDER'.

ENDCLASS.                    "LCL_OPERATION

* ----------------------------------------------------------------------*
CLASS abap_unit_test3 DEFINITION FOR TESTING.
  PUBLIC SECTION.
    DATA lcl_class TYPE REF TO lcl_operation.
    METHODS: run FOR TESTING.
ENDCLASS.                    "ABAP_UNIT_TEST DEFINITION
*----------------------------------------------------------------------*
*       CLASS abap_unit_test IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS abap_unit_test3 IMPLEMENTATION.

  METHOD run.
    DATA return TYPE string.
    DATA bool TYPE abap_bool.
    CREATE OBJECT lcl_class.
    return = lcl_class->get_file_extension( ).
    bool = lcl_class->is_binary( ).
  ENDMETHOD.                    "run

ENDCLASS.                    "abap_unit_test2 IMPLEMENTATION
************************************************************************
CLASS lcl_operation IMPLEMENTATION.

  METHOD get_file_extension.

*   Initialize
    CLEAR rv_file_extension.

*   Return empty string if object behind is a folder
    IF object_type = lcl_operation=>object_type_folder. RETURN. ENDIF.

*   Split path
    DATA: parts     TYPE TABLE OF string,
          part      TYPE string,
          i         TYPE int4,
          extension TYPE string.
    SPLIT me->relative_path AT '/' INTO TABLE parts.
    i = lines( parts ).
    READ TABLE parts INTO part INDEX i.
*   Get file extension
    SPLIT part AT '.' INTO TABLE parts.
    i = lines( parts ).
    IF i > 1.
      READ TABLE parts INTO extension INDEX i.
      TRANSLATE extension TO UPPER CASE.                 "#EC TRANSLANG
    ENDIF.
*   Return
    IF extension IS INITIAL. RETURN. ENDIF.
    CONCATENATE '.' extension INTO extension.
    rv_file_extension = extension.

  ENDMETHOD.                    "get_file_extension

  METHOD is_binary.

*   Check file type
    rv_is_binary = abap_undefined.
    IF me->object_type = lcl_operation=>object_type_binary_file.
      rv_is_binary = abap_true.
    ELSEIF me->object_type = lcl_operation=>object_type_text_file.
      rv_is_binary = abap_false.
    ENDIF.

  ENDMETHOD.                    "is_binary

ENDCLASS.                    "lcl_operation


************************************************************************
* Class LCL_UI5_LOCAL_APP
*
* represents a ui5 application on the local disk.
*
* The class is used for upload and download. It knows e.g. the home
* directory or whether a file is of binary or text type. etc.
************************************************************************
CLASS lcl_ui5_local_app DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-DATA:    binary_file_patterns_file TYPE string VALUE '.Ui5RepositoryBinaryFiles',
                   file_system               TYPE REF TO lcl_file_system,
                   message                   TYPE string,
                   text_file_patterns_file   TYPE string VALUE '.Ui5RepositoryTextFiles',
                   ignore_file_patterns_file TYPE string VALUE '.Ui5RepositoryIgnore'.
    DATA:          binary_file_patterns           TYPE TABLE OF string,
                   binary_file_identification_msg TYPE string,
                   home_directory                 TYPE string,
                   text_file_patterns             TYPE TABLE OF string,
                   text_file_identification_msg   TYPE string,
                   upload_ignores                 TYPE TABLE OF string,
                   upload_ignore_message          TYPE string,
                   upload_operations              TYPE TABLE OF REF TO lcl_operation.
    TYPES:         download_operations            TYPE TABLE OF REF TO lcl_operation.
    CLASS-METHODS: class_constructor,
      add_default_bin_file_patterns  CHANGING cv_file_patterns TYPE string_table,
      add_default_ignore_patterns    CHANGING cv_file_patterns TYPE string_table,
      add_default_text_file_patterns CHANGING cv_file_patterns TYPE string_table,
      get_instance                   RETURNING VALUE(rv_self) TYPE REF TO lcl_ui5_local_app.
    METHODS:       conciliate_download_operations IMPORTING iv_path                TYPE string DEFAULT ''
                                                            iv_ignores             LIKE upload_ignores
                                                  CHANGING  cv_download_operations TYPE download_operations,
      determine_upload_operations    IMPORTING iv_directory      TYPE string
                                               iv_ignores        LIKE upload_ignores
                                     RETURNING VALUE(rv_success) TYPE abap_bool,
      set_home_directory             IMPORTING iv_home_directory TYPE string.

  PRIVATE SECTION.
    METHODS:       determine_binary_file_patterns,
      determine_text_file_patterns,
      determine_upload_ignores,
      is_binary_file                 IMPORTING iv_file_path             TYPE string
                                     RETURNING VALUE(rv_is_binary_file) TYPE abap_bool,
      is_file_to_be_ignored          IMPORTING iv_file_path     TYPE string
                                     RETURNING VALUE(rv_ignore) TYPE abap_bool,
      is_text_file                   IMPORTING iv_file_path           TYPE string
                                     RETURNING VALUE(rv_is_text_file) TYPE abap_bool.
    CLASS-DATA:    self                           TYPE REF TO lcl_ui5_local_app.

ENDCLASS.                    "LCL_UI5_LOCAL_APP DEFINITION

************************************************************************
CLASS lcl_ui5_local_app IMPLEMENTATION.

  METHOD class_constructor.
    CREATE OBJECT self.
    file_system = lcl_file_system=>get_instance( ).

  ENDMETHOD.                    "class_constructor

  METHOD conciliate_download_operations.

*   Check input
    IF iv_path IS INITIAL. RETURN. ENDIF.
    IF lines( cv_download_operations ) = 0. RETURN. ENDIF.

*   Walk through folder to be conciliated
    DATA : directories     TYPE filetable, files TYPE filetable, entry  TYPE file_table,
           file_count      TYPE i, directory_count TYPE i.
    cl_gui_frontend_services=>directory_list_files( EXPORTING directory = iv_path files_only = abap_true
                                                    CHANGING  file_table = files count = file_count ).
    cl_gui_frontend_services=>directory_list_files( EXPORTING directory = iv_path directories_only = abap_true
                                                    CHANGING  file_table = directories count = directory_count ).
    IF sy-subrc <> 0. RETURN. ENDIF.

*   Conciliate files first
    LOOP AT files INTO entry.

*     Check if file is going to be updated
      DATA: file_gets_updated TYPE abap_bool. file_gets_updated = abap_false.
      DATA: operation TYPE REF TO lcl_operation.
      DATA: file_path TYPE string.
      CONCATENATE iv_path lcl_file_system=>path_separator entry INTO file_path.
      LOOP AT cv_download_operations INTO operation.
        IF operation->full_path = file_path.
          file_gets_updated = abap_true.
          EXIT.
        ENDIF.
      ENDLOOP.

*     Check if file is on the ignore list
      DATA: file_is_to_be_ignored TYPE abap_bool. file_is_to_be_ignored = abap_false.
      IF lcl_function=>text_matches_pattern( iv_text = file_path iv_pattern_list = iv_ignores ) = abap_true.
        file_is_to_be_ignored = abap_true.
      ENDIF.

*     Register file for deletion if it does not get updated
*       and if it is not to be ignored
      IF file_gets_updated = abap_false.
        CREATE OBJECT operation.
        operation->operation = lcl_operation=>delete_file.
        IF file_is_to_be_ignored = abap_true. operation->operation = lcl_operation=>ignore_file. ENDIF.
        operation->full_path = file_path.
        operation->object_type = lcl_operation=>object_type_file.
        APPEND operation TO cv_download_operations.
      ENDIF.

    ENDLOOP.

*   Now look into folders
    LOOP AT directories INTO entry.
      DATA: directory_path TYPE string.
      CONCATENATE iv_path lcl_file_system=>path_separator entry INTO directory_path.

*     Check if folder is going to be updated
      DATA: folder_gets_updated TYPE abap_bool. folder_gets_updated = abap_false.
      DATA: folder_path TYPE string.
      CONCATENATE iv_path lcl_file_system=>path_separator entry INTO folder_path.
      LOOP AT cv_download_operations INTO operation.
        IF operation->full_path = folder_path.
          folder_gets_updated = abap_true.
          EXIT.
        ENDIF.
      ENDLOOP.

*     Check if folder is to be ignored
      DATA: folder_is_to_be_ignored TYPE abap_bool. folder_is_to_be_ignored = abap_false.
      IF lcl_function=>text_matches_pattern( iv_text = folder_path iv_pattern_list = iv_ignores ) = abap_true.
        folder_is_to_be_ignored = abap_true.
      ENDIF.

*     Conciliate sub folder
      me->conciliate_download_operations( EXPORTING iv_path = directory_path
                                                    iv_ignores = iv_ignores
                                          CHANGING  cv_download_operations = cv_download_operations ).

*     Register folder for deletion it it does not get updated
*       and if it is not to be ignored
      IF folder_gets_updated = abap_false.
        CREATE OBJECT operation.
        operation->operation = lcl_operation=>delete_folder.
        IF folder_is_to_be_ignored = abap_true. operation->operation = lcl_operation=>ignore_folder. ENDIF.
        operation->full_path = folder_path.
        operation->object_type = lcl_operation=>object_type_folder.
        APPEND operation TO cv_download_operations.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.                    "conciliate_download_operations

  METHOD determine_binary_file_patterns.

*   Try to access file containing binary file patterns
    DATA: binary_file_patterns_file TYPE string, file_length TYPE i,
          lines                     TYPE STANDARD TABLE OF string.
    CONCATENATE home_directory lcl_file_system=>path_separator me->binary_file_patterns_file INTO binary_file_patterns_file.
    CALL METHOD cl_gui_frontend_services=>gui_upload
      EXPORTING
        filename                = binary_file_patterns_file
        filetype                = 'ASC'
        read_by_line            = 'X'
      IMPORTING
        filelength              = file_length
*       header                  =
      CHANGING
        data_tab                = lines
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        not_supported_by_gui    = 17
        error_no_gui            = 18
        OTHERS                  = 19.

    IF sy-subrc = 0.
      binary_file_identification_msg = text-060. "'File '.Ui5RepositoryBinaryFiles' has been considered to identify binary files.'
    ELSE.
      binary_file_identification_msg = 'Binary files have been identified from standard settings.'(061).
    ENDIF.

*   Build list of patterns identifying binary files
*   ... Standard binary file patterns
    me->add_default_bin_file_patterns( CHANGING cv_file_patterns = self->binary_file_patterns ).
*   ... patterns from '.Ui5RepositoryBinaryFiles' file
    DATA: line TYPE string.
    LOOP AT lines INTO line.
      APPEND line TO me->binary_file_patterns.
    ENDLOOP.

  ENDMETHOD.                    "determine_binary_file_patterns

  METHOD determine_text_file_patterns.

*   Try to access file containing text file patterns
    DATA: text_file_patterns_file TYPE string, file_length TYPE i,
          lines                   TYPE STANDARD TABLE OF string.
    CONCATENATE home_directory lcl_file_system=>path_separator me->text_file_patterns_file INTO text_file_patterns_file.
    CALL METHOD cl_gui_frontend_services=>gui_upload
      EXPORTING
        filename                = text_file_patterns_file
        filetype                = 'ASC'
        read_by_line            = 'X'
      IMPORTING
        filelength              = file_length
*       header                  =
      CHANGING
        data_tab                = lines
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        not_supported_by_gui    = 17
        error_no_gui            = 18
        OTHERS                  = 19.

    IF sy-subrc = 0.
      text_file_identification_msg = 'File ".Ui5RepositoryTextFiles" has been considered to identify text files.'(062).
    ELSE.
      text_file_identification_msg = 'Text files have been identified from standard settings.'(063).
    ENDIF.

*   Build list of patterns identifying text files
*   ... Standard text file patterns
    me->add_default_text_file_patterns( CHANGING cv_file_patterns = self->text_file_patterns ).
*   ... Patterns from '.Ui5RepositoryTextFiles' file
    DATA: line TYPE string.
    LOOP AT lines INTO line.
      APPEND line TO me->text_file_patterns.
    ENDLOOP.

  ENDMETHOD.                    "determine_text_file_patterns

* Determines patterns for files to be ignored during the upload of a UI5 application
*
* In case a .Ui5RepositoryIgnore file is found in the directory of the UI5 application
* its content is used to decide if a file is considered in the upload operation.
*
* Example content:
*
* .c#
* ^.*\.ttf$
* ^.*[/|\\]build([/|\\].*)?$
*
* In this case all files which contain the sub expression ".c#" in their full path
* string are ignored by the upload operation. Furthermore files with the extension
* ".ttf" are ignored as well. In this example "^.*\.ttf$" is detected as a regular
* expression because it starts with a "^" and ends with a "$".
* Finally the build directory and everything below gets ignored.
*
* If a .Ui5RepIgnore file is not found a standard list of ignore patterns is used:
* So there's no need for a user to think about this topic in a simple case.
*
* Remark: In Eclipse the ignore files are specified by a team provider setting.
*
  METHOD determine_upload_ignores.

*   Try to access upload ignore file
    DATA: ignorefile  TYPE string, file_length TYPE i,
          lines       TYPE STANDARD TABLE OF string.
    CONCATENATE home_directory lcl_file_system=>path_separator me->ignore_file_patterns_file INTO ignorefile.
    CALL METHOD cl_gui_frontend_services=>gui_upload
      EXPORTING
        filename                = ignorefile
        filetype                = 'ASC'
        read_by_line            = 'X'
      IMPORTING
        filelength              = file_length
*       header                  =
      CHANGING
        data_tab                = lines
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        not_supported_by_gui    = 17
        error_no_gui            = 18
        OTHERS                  = 19.

    DATA: use_standard_ignores TYPE abap_bool VALUE abap_false.
    IF sy-subrc <> 0.
      use_standard_ignores = abap_true.
    ENDIF.

*   Build list of files to ignore during upload
    IF use_standard_ignores = abap_true.
      me->add_default_ignore_patterns( CHANGING cv_file_patterns = self->upload_ignores ).
      upload_ignore_message = 'Items to be ignored have been determined from the built-in standard settings.'(011).
    ELSE.
      DATA: line TYPE string.
      LOOP AT lines INTO line.
        APPEND line TO me->upload_ignores.
      ENDLOOP.
      upload_ignore_message = text-012. "'Items to be ignored have been determined from the '.Ui5RepositoryIgnore' file.'
    ENDIF.

  ENDMETHOD.                    "determine_upload_ignores

  METHOD determine_upload_operations.

*   No upload possible if directory does not exist
    IF file_system->directory_exists( iv_directory ) = abap_false.
      rv_success = abap_false. RETURN.
    ENDIF.

*   Register upload for files and folders in directory
*   ... Read files
    DATA : entries TYPE filetable,
           entry   TYPE file_table,
           count   TYPE i.
    CALL METHOD cl_gui_frontend_services=>directory_list_files
      EXPORTING
        directory                   = iv_directory
        files_only                  = abap_true                                                                                                                                                                                                 "filter = '*.*'
      CHANGING
        file_table                  = entries                                                                                                                                                                                     "directories_only = abap_true
        count                       = count
      EXCEPTIONS
        cntl_error                  = 1
        directory_list_files_failed = 2
        wrong_parameter             = 3
        error_no_gui                = 4
        not_supported_by_gui        = 5
        OTHERS                      = 6.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
*   ... Register file upload operations
    DATA: upload_operation TYPE REF TO lcl_operation.
    LOOP AT entries INTO entry.
*     Create upload operation
      CREATE OBJECT upload_operation.
      upload_operation->operation = lcl_operation=>upload_file.
      upload_operation->object_name = entry.
*     Build full path
      DATA: full_path TYPE string.
      CONCATENATE iv_directory file_system->path_separator entry INTO full_path.
      upload_operation->full_path = full_path.
      upload_operation->relative_path = upload_operation->full_path.
*     Build relative path
      DATA: home_directory_path TYPE string.
      CONCATENATE home_directory lcl_file_system=>path_separator INTO home_directory_path.
      REPLACE home_directory_path IN upload_operation->relative_path WITH ''.
      REPLACE ALL OCCURRENCES OF '\' IN upload_operation->relative_path WITH '/'.
*     Check if entry is to be ignored
      DATA: is_file_to_be_ignored TYPE abap_bool. is_file_to_be_ignored = me->is_file_to_be_ignored( full_path ).
      IF is_file_to_be_ignored = abap_true. upload_operation->operation = lcl_operation=>ignore_file. ENDIF.
*     Determine file type
      upload_operation->object_type = lcl_operation=>object_type_file.
      IF me->is_text_file( upload_operation->relative_path ) = abap_true. upload_operation->object_type = lcl_operation=>object_type_text_file. ENDIF.
      IF me->is_binary_file( upload_operation->relative_path ) = abap_true. upload_operation->object_type = lcl_operation=>object_type_binary_file. ENDIF.
*     ... Try to determine from mime type
      IF upload_operation->object_type = lcl_operation=>object_type_file.
        DATA: extension TYPE string,
              ext       TYPE char20,
              mimetype  TYPE mimetypes-type.
        extension = upload_operation->get_file_extension( ). ext = extension.
        CALL FUNCTION 'SDOK_MIMETYPE_GET'
          EXPORTING
            extension = ext
          IMPORTING
            mimetype  = mimetype.
        IF mimetype = 'image'.
          upload_operation->object_type = lcl_operation=>object_type_binary_file.
        ELSE.
          upload_operation->operation = lcl_operation=>ignore_file.
          upload_operation->message = 'File type unknown'(072).
        ENDIF.
      ENDIF.
*
      APPEND upload_operation TO upload_operations.
    ENDLOOP.

*   ... Read folders
    DATA : folders TYPE filetable.
    CALL METHOD cl_gui_frontend_services=>directory_list_files
      EXPORTING
        directory                   = iv_directory
        "filter                     = '*.*'
        "files_only                 = abap_false
        directories_only            = abap_true
      CHANGING
        file_table                  = folders
        count                       = count
      EXCEPTIONS
        cntl_error                  = 1
        directory_list_files_failed = 2
        wrong_parameter             = 3
        error_no_gui                = 4
        not_supported_by_gui        = 5
        OTHERS                      = 6.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
*   ... Register operations to create folders
*       and its files
    LOOP AT folders INTO entry.
*     Create upload operation
      CREATE OBJECT upload_operation.
      upload_operation->operation = lcl_operation=>create_folder.
      upload_operation->object_name = entry.
      upload_operation->object_type = lcl_operation=>object_type_folder.
*     Build full path
      CONCATENATE iv_directory file_system->path_separator entry INTO full_path.
      upload_operation->full_path = full_path.
*     Build relative path
      upload_operation->relative_path = upload_operation->full_path.
      CONCATENATE home_directory lcl_file_system=>path_separator INTO home_directory_path.
      REPLACE home_directory_path IN upload_operation->relative_path WITH ''.
      REPLACE ALL OCCURRENCES OF '\' IN upload_operation->relative_path WITH '/'.
*     Decide if folder is to be ignored
      DATA: is_folder_to_be_ignored TYPE abap_bool. is_folder_to_be_ignored = me->is_file_to_be_ignored( full_path ).
      IF is_folder_to_be_ignored = abap_true. upload_operation->operation = lcl_operation=>ignore_folder. ENDIF.
      APPEND upload_operation TO upload_operations.
*     Skip resolution of source code repository folders
      DATA: is_code_repository TYPE abap_bool. is_code_repository = abap_false.
      IF upload_operation->object_name = '.git'. is_code_repository = abap_true. ENDIF.
      IF is_code_repository = abap_true AND is_folder_to_be_ignored = abap_true. CONTINUE. ENDIF.
*
      determine_upload_operations( iv_directory = full_path iv_ignores = me->upload_ignores ).
    ENDLOOP.

    rv_success = abap_true.

  ENDMETHOD.                    "determine_upload_package

  METHOD add_default_bin_file_patterns.

*   ... Add default binary patterns
    DATA: binary_file_pattern TYPE string.
    binary_file_pattern = '.zip'.                     APPEND binary_file_pattern TO cv_file_patterns.
    binary_file_pattern = '.war'.                     APPEND binary_file_pattern TO cv_file_patterns.
    binary_file_pattern = '.jpg'.                     APPEND binary_file_pattern TO cv_file_patterns.
    binary_file_pattern = '.gif'.                     APPEND binary_file_pattern TO cv_file_patterns.
    binary_file_pattern = '.png'.                     APPEND binary_file_pattern TO cv_file_patterns.
    binary_file_pattern = '.ttf'.                     APPEND binary_file_pattern TO cv_file_patterns.
    binary_file_pattern = '.eot'.                     APPEND binary_file_pattern TO cv_file_patterns.
    binary_file_pattern = '.woff'.                     APPEND binary_file_pattern TO cv_file_patterns.
    binary_file_pattern = '.woff2'.                     APPEND binary_file_pattern TO cv_file_patterns.
    binary_file_pattern = '.svg'.                     APPEND binary_file_pattern TO cv_file_patterns.
    binary_file_pattern = '^.*\.class$'.              APPEND binary_file_pattern TO cv_file_patterns.

  ENDMETHOD.                    "add_default_bin_file_patterns

  METHOD add_default_ignore_patterns.

*   ... Add default binary patterns
    DATA: ignore_file_pattern TYPE string.
    ignore_file_pattern = '.git'.                     APPEND ignore_file_pattern TO cv_file_patterns.
    ignore_file_pattern = '^.*[/|\\]build([/|\\].*)?$'.
    APPEND ignore_file_pattern TO cv_file_patterns.

  ENDMETHOD.                    "add_default_ignore_patterns

  METHOD add_default_text_file_patterns.

*   Add default text file patterns
    DATA: text_file_pattern TYPE string.
    text_file_pattern = '.txt'.                       APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '.html'.                      APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '.js'.                        APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '.json'.                      APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '.less'.                      APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '.css'.                       APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '.htm'.                       APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '.xml'.                       APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = 'manifest.mf'.                APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '.classpath'.                 APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '.properties'.                APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '.project'.                   APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '.settings/'.                 APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '^.*\.control$'.              APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '^.*\.json$'.                 APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '^.*\.less$'.                 APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '^.*\.library$'.              APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '^.*\.theming$'.              APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '^.*\.change$'.               APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '^.*\.appdescr$'.             APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '^.*\.appdescr_variant$'.     APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '.Ui5RepositoryAppSetup'.     APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '.UI5RepositoryIgnore'.       APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '.Ui5RepositoryBinaryFiles'.  APPEND text_file_pattern TO cv_file_patterns.
    text_file_pattern = '.Ui5RepositoryTextFiles'.    APPEND text_file_pattern TO cv_file_patterns.

  ENDMETHOD.                    "add_default_text_file_patterns

  METHOD get_instance.
    rv_self = self.
  ENDMETHOD.                    "get_instance

  METHOD is_binary_file.

    rv_is_binary_file = abap_undefined.
    IF ( lcl_function=>text_matches_pattern( iv_text = iv_file_path iv_pattern_list = me->binary_file_patterns ) = abap_true ).
      rv_is_binary_file = abap_true.
    ENDIF.

  ENDMETHOD.                    "is_binary_file

  METHOD is_file_to_be_ignored.

    rv_ignore = abap_false.
    IF ( lcl_function=>text_matches_pattern( iv_text = iv_file_path iv_pattern_list = me->upload_ignores ) = abap_true ).
      rv_ignore = abap_true.
    ENDIF.

  ENDMETHOD.                    "is_file_to_be_ignored

  METHOD is_text_file.

    rv_is_text_file = abap_undefined.
    IF ( lcl_function=>text_matches_pattern( iv_text = iv_file_path iv_pattern_list = me->text_file_patterns ) = abap_true ).
      rv_is_text_file = abap_true.
    ENDIF.

  ENDMETHOD.                    "is_text_file

  METHOD set_home_directory.

*   Remember
    me->home_directory = iv_home_directory.

*   Initialize
    CLEAR me->binary_file_patterns.
    CLEAR me->text_file_patterns.
    CLEAR me->upload_ignores.
    CLEAR me->upload_operations.

*   Determine files to ignore in upload
    me->determine_binary_file_patterns( ).
    me->determine_text_file_patterns( ).
    me->determine_upload_ignores( ).

  ENDMETHOD.                    "set_home_directory

ENDCLASS.                    "LCL_UI5_LOCAL_APP IMPLEMENTATION


************************************************************************
* Class LCL_UI5_REPOSITORY
*
* represents a UI5 Repository and the UI5 application it contains.
************************************************************************
CLASS lcl_ui5_repository DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-DATA:    message                        TYPE string.
    TYPES:         BEGIN OF upload_parameters,
                     description       TYPE string,
                     package           TYPE devclass,
                     transport_request TYPE trkorr,
                     code_page_ui      TYPE string,
                     code_page_abap    TYPE cpcodepage,
                     code_page_java    TYPE string,
                   END OF upload_parameters,
                   BEGIN OF download_parameters,
                     code_page_ui   TYPE string,
                     code_page_abap TYPE cpcodepage,
                     code_page_java TYPE string,
                   END OF download_parameters,
                   upload_operations TYPE TABLE OF REF TO lcl_operation.
    DATA:          already_exists                 TYPE abap_bool,
                   api                            TYPE REF TO /ui5/if_ui5_rep_dt,
                   binary_file_identification_msg TYPE string,
                   binary_file_patterns           TYPE TABLE OF string,
                   name                           TYPE string,
                   text_file_identification_msg   TYPE string,
                   text_file_patterns             TYPE TABLE OF string,
                   ignores                        TYPE TABLE OF string,
                   ignores_identification_msg     TYPE string.
    CLASS-METHODS: class_constructor,
      get_instance                   RETURNING VALUE(rv_self) TYPE REF TO lcl_ui5_repository,
      evaluate_authorization         RETURNING  VALUE(rv_message) TYPE string.
    DATA:          download_operations            TYPE TABLE OF REF TO lcl_operation.
    METHODS:       conciliate_upload_operations   IMPORTING iv_path              TYPE string DEFAULT ''
                                                  CHANGING  cv_upload_operations TYPE upload_operations,
      determine_download_operations  IMPORTING iv_relative_path    TYPE string DEFAULT ''
                                               iv_target_directory TYPE string,
      get_download_parameters        RETURNING VALUE(rv_download_parameters) TYPE download_parameters
                                     RAISING   lcx_canceled,
      get_mime_type_for_upload       IMPORTING iv_operation        TYPE REF TO lcl_operation
                                     RETURNING VALUE(rv_mime_type) TYPE string,
      get_upload_parameters          IMPORTING VALUE(iv_transport_request_only) TYPE abap_bool DEFAULT abap_false
                                     RETURNING VALUE(rv_upload_parameters)      TYPE upload_parameters
                                     RAISING   lcx_canceled,
      set_name                       IMPORTING iv_name TYPE string.

  PRIVATE SECTION.
    METHODS:       determine_binary_file_patterns,
      determine_text_file_patterns,
      determine_ignores,
      is_binary_file                 IMPORTING iv_file_path             TYPE string
                                     RETURNING VALUE(rv_is_binary_file) TYPE abap_bool,
      is_file_to_be_ignored          IMPORTING iv_file_path     TYPE string
                                     RETURNING VALUE(rv_ignore) TYPE abap_bool,
      is_text_file                   IMPORTING iv_file_path           TYPE string
                                     RETURNING VALUE(rv_is_text_file) TYPE abap_bool.
    CLASS-DATA:    self                           TYPE REF TO lcl_ui5_repository.

ENDCLASS.                    "lcl_ui5_repository DEFINITION
*----------------------------------------------------------------------*
*       CLASS abap_unit_test DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS abap_unit_test4 DEFINITION FOR TESTING.
  PUBLIC SECTION.
    DATA lcl_class TYPE REF TO lcl_ui5_repository.
    METHODS: run FOR TESTING.
ENDCLASS.                    "ABAP_UNIT_TEST DEFINITION
*----------------------------------------------------------------------*
*       CLASS abap_unit_test IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS abap_unit_test4 IMPLEMENTATION.

  METHOD run.
***    lcl_class = lcl_ui5_repository=>get_instance( ).
***    DATA mess TYPE string.
***    mess = lcl_class->evaluate_authorization( ).
***
***    DATA l_path TYPE string.
***    DATA l_op TYPE TABLE OF REF TO lcl_operation.
***    lcl_class->conciliate_upload_operations( EXPORTING iv_path = l_path CHANGING cv_upload_operations = l_op ).
***    DATA l_rel_path TYPE string.
***    DATA l_dir TYPE string.
****    lcl_class->determine_download_operations( EXPORTING iv_relative_path = l_rel_path iv_target_directory = l_dir ).
***    DATA l_down_para TYPE lcl_ui5_repository=>download_parameters.
***    TRY.
****        l_down_para = lcl_class->get_download_parameters( ).
***      CATCH lcx_canceled.
***    ENDTRY.
***    DATA lcl_op TYPE REF TO lcl_operation.
***    CREATE OBJECT lcl_op.
***    DATA l_mime TYPE string.
***    l_mime = lcl_class->get_mime_type_for_upload( iv_operation = lcl_op ).
****    DATA l_trans_only TYPE abap_bool.
***    DATA l_up_para TYPE lcl_ui5_repository=>upload_parameters.
***    TRY.
****        l_up_para = lcl_class->get_upload_parameters( iv_transport_request_only = abap_true ).
***      CATCH lcx_canceled.
***    ENDTRY.
***    DATA l_set_name TYPE string.
***    lcl_class->set_name( iv_name = l_set_name ).

  ENDMETHOD.                    "run
ENDCLASS.                    "abap_unit_test IMPLEMENTATION
************************************************************************
CLASS lcl_ui5_repository IMPLEMENTATION.

  METHOD class_constructor.
    CREATE OBJECT self.
  ENDMETHOD.                    "class_constructor

  METHOD get_mime_type_for_upload.

*   Check input
    CLEAR rv_mime_type.
    IF iv_operation IS INITIAL. RETURN. ENDIF.

*   Check if file is known to be text
    IF iv_operation->object_type = lcl_operation=>object_type_text_file.
      rv_mime_type = 'text/plain'.
      RETURN.
    ENDIF.

*   Check if file is known to be binary
    IF iv_operation->object_type = lcl_operation=>object_type_binary_file.
      rv_mime_type = 'image'. "Although this is not true neccessarily: This should trigger a binary upload
      RETURN.
    ENDIF.

*   Determine file extension
    DATA: extension TYPE string.
    extension = iv_operation->get_file_extension( ).

*   Determine mime type using file extension via SDOK_MIMETYPE_GET
    DATA: mimetype TYPE mimetypes-type,
          ext      TYPE char20.
    ext = extension.
    CALL FUNCTION 'SDOK_MIMETYPE_GET'
      EXPORTING
        extension = ext
      IMPORTING
        mimetype  = mimetype.
    .
    rv_mime_type = mimetype.

  ENDMETHOD.                    "get_mime_type_for_upload

  METHOD conciliate_upload_operations.

*   Nothing to do if repository already exists
    IF me->already_exists = abap_false. RETURN. ENDIF.

*   Walk through content of ui5 repository
    DATA: children TYPE string_table,
          child    TYPE string.
    TRY.
        children = me->api->get_folder_children( iv_path ).
      CATCH /ui5/cx_ui5_rep_dt.
    ENDTRY.
    LOOP AT children INTO child.

*     Check if child is going to be updated
*     and if it is a folder
      DATA: child_gets_updated TYPE abap_bool. child_gets_updated = abap_false.
      DATA: operation TYPE REF TO lcl_operation.
      LOOP AT cv_upload_operations INTO operation.
        IF operation->relative_path = child
           "and not ( operation->operation = lcl_operation=>ignore_file
           "          or operation->operation = lcl_operation=>ignore_folder )
          .
          child_gets_updated = abap_true.
          EXIT.
        ENDIF.
      ENDLOOP.
      DATA: child_is_folder TYPE abap_bool.
      TRY.
          child_is_folder = me->api->check_is_folder( child ).
        CATCH /ui5/cx_ui5_rep_dt.
      ENDTRY.

*     Conciliate sub folder
      IF child_is_folder = abap_true.
        conciliate_upload_operations( EXPORTING iv_path = child  CHANGING cv_upload_operations = cv_upload_operations ).
        IF child_gets_updated = abap_false.
          CREATE OBJECT operation.
          operation->operation = lcl_operation=>delete_folder.
          operation->relative_path = child.
          operation->object_type = lcl_operation=>object_type_folder.
          APPEND operation TO cv_upload_operations.
        ENDIF.
      ELSE.
*     Conciliate file
        IF child_gets_updated = abap_false.
          CREATE OBJECT operation.
          operation->operation = lcl_operation=>delete_file.
          operation->relative_path = child.
          operation->object_type = lcl_operation=>object_type_file.
          APPEND operation TO cv_upload_operations.
        ENDIF.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.                    "conciliate_upload_operations

  METHOD determine_download_operations.

*   Initialize download operation table if starting with root path
    IF iv_relative_path IS INITIAL. CLEAR me->download_operations. ENDIF.

*   Confirm repository exists
    IF me->already_exists = abap_false. RETURN. ENDIF.

*   Walk through content of ui5 repository
    DATA: children TYPE string_table,
          child    TYPE string.
    TRY.
        children = me->api->get_folder_children( iv_relative_path ).
      CATCH /ui5/cx_ui5_rep_dt.
    ENDTRY.
    LOOP AT children INTO child.

*     Check if child is a folder
      DATA: child_is_folder TYPE abap_bool.
      TRY.
          child_is_folder = me->api->check_is_folder( child ).
        CATCH /ui5/cx_ui5_rep_dt.
      ENDTRY.

*     Download sub folder
      IF child_is_folder = abap_true.
        DATA: operation TYPE REF TO lcl_operation.
        CREATE OBJECT operation.
        operation->operation = lcl_operation=>create_folder.
        operation->relative_path = child.
        operation->object_type = lcl_operation=>object_type_folder.
        CONCATENATE iv_target_directory lcl_file_system=>path_separator child INTO operation->full_path.
        REPLACE ALL OCCURRENCES OF '/' IN operation->full_path WITH lcl_file_system=>path_separator.
        APPEND operation TO me->download_operations.
        determine_download_operations( iv_relative_path = child iv_target_directory = iv_target_directory ).
*     Download file
      ELSE.
        CREATE OBJECT operation.
        operation->operation = lcl_operation=>download_file.
        operation->relative_path = child.
        operation->object_type = lcl_operation=>object_type_file.
        IF me->is_text_file( child ) = abap_true. operation->object_type = lcl_operation=>object_type_text_file. ENDIF.
        IF me->is_binary_file( child ) = abap_true. operation->object_type = lcl_operation=>object_type_binary_file. ENDIF.
        CONCATENATE iv_target_directory lcl_file_system=>path_separator child INTO operation->full_path.
        REPLACE ALL OCCURRENCES OF '/' IN operation->full_path WITH lcl_file_system=>path_separator.
        APPEND operation TO me->download_operations.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.                    "determine_download_operations

  METHOD determine_binary_file_patterns.

*   Try to access file containing binary file patterns
    DATA: binary_file_patterns_file TYPE string, file_length TYPE i,
          lines                     TYPE STANDARD TABLE OF string.
    DATA: file_content                  TYPE xstring,
          file_content_as_string        TYPE string,
          bin_file_patterns_file_exists TYPE abap_bool.
    TRY.
        bin_file_patterns_file_exists = abap_true.
        me->api->get_file( EXPORTING iv_path = lcl_ui5_local_app=>binary_file_patterns_file
                           IMPORTING ev_file_content = file_content ).
        file_content_as_string = /ui5/cl_ui5_rep_utility=>convert_xstring_2_string( file_content ).
        lines = /ui5/cl_ui5_rep_utility=>code_string_2_code_tab( file_content_as_string ).
      CATCH /ui5/cx_ui5_rep_dt.
        bin_file_patterns_file_exists = abap_false.
    ENDTRY.

    IF bin_file_patterns_file_exists = abap_true.
      binary_file_identification_msg = 'File ".Ui5RepositoryBinaryFiles" has been considered to identify binary files.'(060).
    ELSE.
      binary_file_identification_msg = text-061. "'File '.Ui5RepositoryBinaryFiles' has been considered to identify binary files.'
    ENDIF.

*   Build list of patterns identifying binary files
*   ... Standard binary patterns
    lcl_ui5_local_app=>add_default_bin_file_patterns( CHANGING cv_file_patterns = self->binary_file_patterns ).
*   ... plus patterns from '.Ui5RepositoryBinaryFiles' file
    DATA: line TYPE string.
    LOOP AT lines INTO line.
      APPEND line TO me->binary_file_patterns.
    ENDLOOP.

  ENDMETHOD.                    "determine_binary_file_patterns

  METHOD determine_ignores.

*   Determine files to be ignored for clean-up in file system during download
    DATA: file_length TYPE i,
          lines       TYPE STANDARD TABLE OF string.
    DATA: file_content                TYPE xstring,
          file_content_as_string      TYPE string,
          ignore_patterns_file_exists TYPE abap_bool.
    TRY.
*   ... Use ignore settings from file
        ignore_patterns_file_exists = abap_true.
        me->api->get_file( EXPORTING iv_path = lcl_ui5_local_app=>ignore_file_patterns_file
                           IMPORTING ev_file_content = file_content ).
        file_content_as_string = /ui5/cl_ui5_rep_utility=>convert_xstring_2_string( file_content ).
        lines = /ui5/cl_ui5_rep_utility=>code_string_2_code_tab( file_content_as_string ).
        me->ignores = lines.
        ignores_identification_msg = text-012. "'Items to be ignored have been determined from the '.Ui5RepositoryIgnore' file.'
      CATCH /ui5/cx_ui5_rep_dt.
*   ... Use built-in standard
        CLEAR me->ignores.
        ignore_patterns_file_exists = abap_false.
        lcl_ui5_local_app=>add_default_ignore_patterns( CHANGING cv_file_patterns = me->ignores ).
        ignores_identification_msg = 'Items to be ignored have been determined from the built-in standard settings.'(011).
    ENDTRY.

  ENDMETHOD.                    "determine_download_ignores

  METHOD determine_text_file_patterns.

*   Try to access file containing text file patterns
    DATA: text_file_patterns_file TYPE string, file_length TYPE i,
          lines                   TYPE STANDARD TABLE OF string.
    DATA: file_content                   TYPE xstring,
          text_file_patterns_file_exists TYPE abap_bool.
    TRY.
        text_file_patterns_file_exists = abap_true.
        me->api->get_file( EXPORTING iv_path = lcl_ui5_local_app=>text_file_patterns_file
                           IMPORTING ev_file_content = file_content ).
      CATCH /ui5/cx_ui5_rep_dt.
        text_file_patterns_file_exists = abap_false.
    ENDTRY.

    IF text_file_patterns_file_exists = abap_true.
      text_file_identification_msg = 'File ".Ui5RepositoryTextFiles" has been considered to identify text files.'(062).
    ELSE.
      text_file_identification_msg = 'Text files have been identified from standard settings.'(063).
    ENDIF.

*   Build list of patterns identifying text files
*   ... Standard text file patterns
    lcl_ui5_local_app=>add_default_text_file_patterns( CHANGING cv_file_patterns = self->text_file_patterns ).
*   ... Plus patterns from '.Ui5RepositoryTextFiles' file
    DATA: line TYPE string.
    LOOP AT lines INTO line.
      APPEND line TO me->text_file_patterns.
    ENDLOOP.

  ENDMETHOD.                    "determine_text_file_patterns

  METHOD get_download_parameters.

*   Initialize
    CLEAR rv_download_parameters.

*   Define fields to be entered on popup
    DATA: field  TYPE sval,
          fields TYPE TABLE OF sval.
    CLEAR fields.

*   ... External Codepage
    field-tabname    = 'TCP00A'.
    field-fieldname  = 'CPATTR'.
    field-fieldtext  = 'External Codepage'(024).
    APPEND field TO fields.

*   Ask for field
    DATA: returncode(1)   TYPE c,
          popup_title(80) TYPE c.
    popup_title       = 'Enter Parameters for Download from the SAPUI5 ABAP Repository ...'(026).
    CALL FUNCTION 'POPUP_GET_VALUES'
      EXPORTING
        popup_title = popup_title
      IMPORTING
        returncode  = returncode
      TABLES
        fields      = fields.

*   Prepare upload parameter object
    IF returncode = 'A'.
      RAISE EXCEPTION TYPE lcx_canceled.
    ELSE.
      LOOP AT fields INTO field.
        IF field-fieldname = 'CPATTR'.
          rv_download_parameters-code_page_ui = field-value.


*         Calculate ABAP and corresponding JAVA code page
*         to be used for upload operation
          DATA: ecp TYPE REF TO lcl_external_code_page.
          TRY.
*             Determine from external code page name entered
              IF rv_download_parameters-code_page_ui IS NOT INITIAL.
                ecp = lcl_external_code_page=>create( rv_download_parameters-code_page_ui ).
                rv_download_parameters-code_page_abap = ecp->get_abap_encoding( ).
                rv_download_parameters-code_page_java = ecp->get_java_encoding( ).
                "rv_upload_parameters-code_page_abap =
                "   lcl_external_code_page=>create( rv_download_parameters-code_page_ui )->get_abap_encoding( ).
              ELSE.
*             Determine from SAPGUI installation if not given
                ecp = lcl_external_code_page=>for_sapgui_installation( ).
                rv_download_parameters-code_page_abap = ecp->get_abap_encoding( ).
                rv_download_parameters-code_page_java = ecp->get_java_encoding( ).
              ENDIF.
            CATCH cx_root.
          ENDTRY.

        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.                    "get_download_parameters

  METHOD get_upload_parameters.

*   Initialize
    CLEAR rv_upload_parameters.

*   Define field to be entered on popup
    DATA: field  TYPE sval,
          fields TYPE TABLE OF sval.
    CLEAR fields.
*   ... Description
    IF iv_transport_request_only = abap_false.
      field-tabname    = 'O2APPLATTR'.
      field-fieldname  = 'TEXT'.
      field-fieldtext  = 'Description'(021). "Text not from DTEL
      APPEND field TO fields.
*   ... Development class
      field-tabname    = 'TADIR'.
      field-fieldname  = 'DEVCLASS'.
      field-fieldtext  = 'Package'(022).
      APPEND field TO fields.
    ENDIF.
*   ... Transport request
    field-tabname    = 'E070'. "'TRHEADER'.
    field-fieldname  = 'TRKORR'.
    field-fieldtext  = 'Transport Request'(023).
    APPEND field TO fields.
*   ... External Codepage
    field-tabname    = 'TCP00A'.
    field-fieldname  = 'CPATTR'.
    field-fieldtext  = 'External Codepage'(024).
    APPEND field TO fields.


*   Ask for field
    DATA: returncode(1)   TYPE c,
          popup_title(80) TYPE c.
    popup_title       = 'Enter Parameters for Upload into BSP Application ...'(020).
    CALL FUNCTION 'POPUP_GET_VALUES'
      EXPORTING
        popup_title = popup_title
      IMPORTING
        returncode  = returncode
      TABLES
        fields      = fields.

*   Prepare upload parameter object
    IF returncode = 'A'.
      RAISE EXCEPTION TYPE lcx_canceled.
    ELSE.
      LOOP AT fields INTO field.
        IF field-fieldname = 'TEXT'.
          rv_upload_parameters-description = field-value.
        ENDIF.
        IF field-fieldname = 'DEVCLASS'.
          rv_upload_parameters-package = field-value.
        ENDIF.
        IF field-fieldname = 'TRKORR'.
          rv_upload_parameters-transport_request = field-value.
        ENDIF.
        IF field-fieldname = 'CPATTR'.
          rv_upload_parameters-code_page_ui = field-value.

*         Calculate ABAP and corresponding JAVA code page
*         to be used for upload operation
          DATA: ecp TYPE REF TO lcl_external_code_page.
          TRY.
*             Determine from external code page name entered
              IF rv_upload_parameters-code_page_ui IS NOT INITIAL.
                ecp = lcl_external_code_page=>create( rv_upload_parameters-code_page_ui ).
                rv_upload_parameters-code_page_abap = ecp->get_abap_encoding( ).
                rv_upload_parameters-code_page_java = ecp->get_java_encoding( ).
                "rv_upload_parameters-code_page_abap =
                "   lcl_external_code_page=>create( rv_upload_parameters-code_page_ui )->get_abap_encoding( ).
              ELSE.
*             Determine from SAPGUI installation if not given
                ecp = lcl_external_code_page=>for_sapgui_installation( ).
                rv_upload_parameters-code_page_abap = ecp->get_abap_encoding( ).
                rv_upload_parameters-code_page_java = ecp->get_java_encoding( ).
              ENDIF.
            CATCH cx_root.
          ENDTRY.

        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.                    "get_upload_parameters

  METHOD get_instance.
    rv_self = self.
  ENDMETHOD.                    "get_instance

* Evaluate authorization available
  METHOD evaluate_authorization.

    rv_message = ''.
    DATA: may_be_insufficient TYPE abap_bool. may_be_insufficient = abap_false.
    DATA: affected TYPE string. affected = ''.

*   S_DEVELOP

    AUTHORITY-CHECK OBJECT 'S_DEVELOP'
             ID 'DEVCLASS' DUMMY
             ID 'OBJTYPE' FIELD 'WAPA'
             ID 'OBJNAME' DUMMY
             ID 'P_GROUP' DUMMY
             ID 'ACTVT' FIELD '02'.
    IF sy-subrc > 0.
      may_be_insufficient = abap_true.
      IF affected IS NOT INITIAL. CONCATENATE affected ', ' INTO affected RESPECTING BLANKS. ENDIF.
      CONCATENATE affected 'S_DEVELOP' INTO affected.
    ENDIF.

* S_ICF_ADM

    AUTHORITY-CHECK OBJECT 'S_ICF_ADM'
             ID 'ICF_TYPE' FIELD 'NODE'
             ID 'ACTVT' FIELD '02'
             ID 'ICF_HOST' DUMMY
             ID 'ICF_NODE' DUMMY
             .
    IF sy-subrc > 0.
      may_be_insufficient = abap_true.
      IF affected IS NOT INITIAL. CONCATENATE affected ', ' INTO affected RESPECTING BLANKS. ENDIF.
      CONCATENATE affected 'S_ICF_ADM' INTO affected.
    ENDIF.

* S_TRANSPRT

    AUTHORITY-CHECK OBJECT 'S_TRANSPRT'
             ID 'TTYPE' FIELD 'TASK'
             ID 'ACTVT' FIELD '02'.

    IF sy-subrc > 0.
      may_be_insufficient = abap_true.
      IF affected IS NOT INITIAL. CONCATENATE affected ', ' INTO affected RESPECTING BLANKS. ENDIF.
      CONCATENATE affected 'S_TRANSPRT' INTO affected.
    ENDIF.


* S_TCODE

    AUTHORITY-CHECK OBJECT 'S_TCODE'
             ID 'TCD' FIELD '*'.
    IF sy-subrc > 4.
      may_be_insufficient = abap_true.
      IF affected IS NOT INITIAL. CONCATENATE affected ', ' INTO affected RESPECTING BLANKS. ENDIF.
      CONCATENATE affected 'S_TCODE' INTO affected.
    ENDIF.

* S_CTS_ADMI

    AUTHORITY-CHECK OBJECT 'S_CTS_ADMI'
             ID 'CTS_ADMFCT' FIELD 'TABL'.

    IF sy-subrc > 4.
      may_be_insufficient = abap_true.
      IF affected IS NOT INITIAL. CONCATENATE affected ', ' INTO affected RESPECTING BLANKS. ENDIF.
      CONCATENATE affected 'S_CTS_ADMI' INTO affected.
    ENDIF.

*   S_CTS_SADM
    IF may_be_insufficient = abap_true.
      AUTHORITY-CHECK OBJECT 'S_CTS_SADM'
               ID 'DOMAIN' DUMMY
               ID 'DESTSYS' DUMMY
               ID 'CTS_ADMFCT' FIELD 'TABL'.
      IF sy-subrc >= 12.
        CONCATENATE affected ' ' 'and'(104) ' S_CTS_ADMI' INTO affected RESPECTING BLANKS.
      ENDIF.
    ENDIF.

*   Prepare authorization message
*   ... in case authorization appears to be insufficient
    IF may_be_insufficient = abap_true.
      rv_message = 'Warning : Authorization may be missing for'(102).
      CONCATENATE '* ' rv_message ' ' affected ' *' INTO rv_message RESPECTING BLANKS.
      IF strlen( rv_message ) > 79.
        rv_message = 'Warning : Authorizations may be missing.'(103).
        CONCATENATE '* ' rv_message ' *' INTO rv_message RESPECTING BLANKS.
      ENDIF.
    ENDIF.

  ENDMETHOD.                    "evaluate_authorization
  METHOD is_binary_file.

    rv_is_binary_file = abap_undefined.
    IF ( lcl_function=>text_matches_pattern( iv_text = iv_file_path iv_pattern_list = me->binary_file_patterns ) = abap_true ).
      rv_is_binary_file = abap_true.
    ENDIF.

  ENDMETHOD.                    "is_binary_file

  METHOD is_file_to_be_ignored.

    rv_ignore = abap_false.
    IF ( lcl_function=>text_matches_pattern( iv_text = iv_file_path iv_pattern_list = me->ignores ) = abap_true ).
      rv_ignore = abap_true.
    ENDIF.

  ENDMETHOD.                    "is_file_to_be_ignored

  METHOD is_text_file.

    rv_is_text_file = abap_undefined.
    IF ( lcl_function=>text_matches_pattern( iv_text = iv_file_path iv_pattern_list = me->text_file_patterns ) = abap_true ).
      rv_is_text_file = abap_true.
    ENDIF.

  ENDMETHOD.                    "is_text_file

  METHOD set_name.

*   Remember name
    me->name = iv_name.

*   Check if UI5 Repository already exists. If yes retrieve API.
    TRY.
        me->api = /ui5/cl_ui5_rep_dt=>/ui5/if_ui5_rep_dt~get_api( iv_name = me->name ).
        me->already_exists  = abap_true.

*       Determine text and binary file patterns
        me->determine_text_file_patterns( ).
        me->determine_binary_file_patterns( ).

*       Determine files to be kept untouched from download
        me->determine_ignores( ).

      CATCH cx_root.
        CLEAR me->api.
        me->already_exists = abap_false.
    ENDTRY.

  ENDMETHOD.                    "set_name


ENDCLASS.                    "lcl_ui5_repository IMPLEMENTATION

************************************************************************
************************************************************************
*                                                                      *
*                  UI5 Repositor Load - Report Code                    *
*                                                                      *
************************************************************************
************************************************************************


************************************************************************
* Global Report Definitions
************************************************************************
TYPE-POOLS: abap.

DATA: file_system            TYPE REF TO lcl_file_system.
DATA: lv_last_message        TYPE string.
DATA: lv_last_messag2        TYPE string.
DATA: lv_message             TYPE string.
"data: lv_authorization_msg   type string.
DATA: lv_result              TYPE abap_bool.
DATA: ui5_app                TYPE REF TO lcl_ui5_local_app.
DATA: ui5_repository         TYPE REF TO lcl_ui5_repository.


************************************************************************
* Selection Screen
************************************************************************

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001. "Specify SAPUI5 App and Select Operation

"selection-screen begin of line. selection-screen comment 1(79) text-001 modif id cap. selection-screen end of line.
"selection-screen uline 1(79).
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 1(79) text-098. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 1(79) text-002. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 1(79) text-003. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 1(79) text-004. SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN SKIP.

* UI5 repository name
PARAMETER : ui5rep TYPE /ui5/ui5_repository_ui OBLIGATORY.
SELECTION-SCREEN SKIP.

* Upload
PARAMETERS: upload RADIOBUTTON GROUP g1.

* Download
PARAMETERS: download RADIOBUTTON GROUP g1.

* Delete
PARAMETERS: delete RADIOBUTTON GROUP g1.
SELECTION-SCREEN SKIP.

* Options
PARAMETERS: adjlnnds TYPE boolean DEFAULT abap_true AS CHECKBOX.
SELECTION-SCREEN SKIP.


* Message
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 1(79) message MODIF ID msg. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 1(79) messag2 MODIF ID msg. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 1(79) authmsg MODIF ID aut. SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b1.

* Remarks
"selection-screen skip.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-089. "selection-screen skip.
"selection-screen begin of line. selection-screen comment 1(79) text-089. selection-screen end of line.
"selection-screen uline 1(79).
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 1(79) text-098. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 1(79) text-105. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 3(79) text-106. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 1(79) defltcp MODIF ID dcp. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 1(79) text-091. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 3(79) text-092. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 3(79) text-093. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 1(79) text-094. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 3(79) text-095. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 3(79) text-096. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 1(79) text-099. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 3(79) text-100. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 3(79) text-101. SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE. SELECTION-SCREEN COMMENT 3(79) text-114. SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b2.


************************************************************************
AT SELECTION-SCREEN OUTPUT.

* Initialize
  ui5_app = lcl_ui5_local_app=>get_instance( ).
  ui5_repository = lcl_ui5_repository=>get_instance( ).
  file_system = lcl_file_system=>get_instance( ).
  IMPORT msg = lv_last_message FROM MEMORY ID 'last_message'. message = lv_last_message.
  IMPORT msg = lv_last_messag2 FROM MEMORY ID 'last_messag2'. messag2 = lv_last_messag2.
  DELETE FROM MEMORY ID 'last_message'.
  DELETE FROM MEMORY ID 'last_messag2'.

*  IMPORT log_msg = lt_messages FROM MEMORY ID 'log_messages'.
*  DELETE FROM MEMORY ID 'log_messages'.
* TODO how to display the log messages

* Check input
  "IF ui5rep IS INITIAL.
  "  message = '* Specify SAPUI5 Application Name *'(025).
  "ENDIF.

* Evaluate authorization
  "lv_authorization_msg = lcl_ui5_repository=>evaluate_authorization( ).
  authmsg = lcl_ui5_repository=>evaluate_authorization( ).

* Calculate default message
  IF defltcp IS INITIAL.
    DATA: ecp               TYPE REF TO lcl_external_code_page,
          default_code_page TYPE string.
    TRY.
        defltcp = text-090.
        ecp = lcl_external_code_page=>for_sapgui_installation( ).
        default_code_page = ecp->get_java_encoding( ).
        REPLACE '%1' IN defltcp WITH default_code_page.
      CATCH cx_root.
        defltcp = text-097.
    ENDTRY.
  ENDIF.

* Hilight caption and message
  LOOP AT SCREEN.
    IF ( screen-group1 = 'CAP' OR screen-group1 = 'MSG' ).
      screen-intensified = '1'.
      MODIFY SCREEN.
    ENDIF.
    IF ( screen-group1 = 'CAP' OR screen-group1 = 'AUT' ).
      screen-intensified = '1'.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

************************************************************************
START-OF-SELECTION.

* Check Prerequisites
  IF ui5rep IS INITIAL.
    lv_message = '* Specify SAPUI5 Application Name *'(025). WRITE: / lv_message.
    lv_last_message = lv_message. EXPORT msg = lv_last_message TO MEMORY ID 'last_message'.
    RETURN.
  ENDIF.

* Set ui5 repository name
  DATA: ui5_repository_name TYPE string. ui5_repository_name = ui5rep.
  ui5_repository->set_name( ui5_repository_name ).

* Upload requested *****
  IF upload EQ 'X'.

*   Initialize
    sy-title = 'Load SAPUI5 Application from File System to the SAPUI5 ABAP Repository'(013).

*   Select source directory
    DATA: title TYPE string. title = 'Specify Source Directory ...'(039).
    DATA: home_directory TYPE string.
    home_directory = file_system->select_directory( iv_title = title ).
    ui5_app->set_home_directory( home_directory ).
    IF  ui5_app->home_directory IS INITIAL.
      lv_message = '* A directory for upload has not been selected. Exiting ...*'(051). WRITE: / lv_message.
      lv_last_message = '* Upload canceled *'. EXPORT msg = lv_last_message TO MEMORY ID 'last_message'.
      SET SCREEN 0.
      RETURN.
    ENDIF.

*   Determine upload operations
    ui5_app->determine_upload_operations( iv_directory = ui5_app->home_directory
                                          iv_ignores = ui5_app->upload_ignores      ).
    ui5_repository->conciliate_upload_operations( CHANGING cv_upload_operations = ui5_app->upload_operations ).

*   Print outcome
*   ... List operations on repository
    IF ui5_repository->already_exists = abap_false.
      DATA: create_repository TYPE string. create_repository = text-009.
      WRITE: AT / '* ', create_repository , '  ', ui5_repository->name, ' *' .
    ELSE.
      DATA: update_repository TYPE string. update_repository = text-010.
      WRITE: AT / '* ', update_repository , '  ', ui5_repository->name, ' *' .
    ENDIF.
    WRITE: /.
*   ... Determine column indent on upload operations
    DATA: shiftright TYPE i.
    DATA: la TYPE i. la = strlen( text-005 ).
    DATA: lb TYPE i. lb = strlen( text-006 ).
    DATA: lc TYPE i. lc = strlen( text-007 ).
    DATA: ld TYPE i. ld = strlen( text-008 ).
    shiftright = lcl_function=>max( a = la b = lb c = lc d = ld ).
    "shiftright = lcl_function=>max( a = strlen( text-005 ) b = strlen( text-006 ) c = strlen( text-007 ) d = strlen( text-008 ) ).
*   ... List upload operations on directories and files
    DATA: upload_operation TYPE REF TO lcl_operation.
    LOOP AT ui5_app->upload_operations INTO upload_operation.
      IF     upload_operation->operation = lcl_operation=>create_folder.
        WRITE: AT /(shiftright) text-005 , '  :  '. "Create Folder
      ELSEIF upload_operation->operation = lcl_operation=>upload_file.
        WRITE: AT /(shiftright) text-006 , '  :  '. "Upload File
      ELSEIF upload_operation->operation = lcl_operation=>ignore_folder.
        WRITE: AT /(shiftright) text-007 , '  :  '. "*** IGNORE ***
      ELSEIF upload_operation->operation = lcl_operation=>ignore_file.
        WRITE: AT /(shiftright) text-008 , '  :  '. "*** IGNORE ***
      ELSEIF upload_operation->operation = lcl_operation=>delete_folder.
        WRITE: AT /(shiftright) text-080 , '  :  '. "Delete Folder
      ELSEIF upload_operation->operation = lcl_operation=>delete_file.
        WRITE: AT /(shiftright) text-081 , '  :  '. "Delete File
      ENDIF.
      IF upload_operation->operation = lcl_operation=>delete_folder
         OR upload_operation->operation = lcl_operation=>delete_file.
        WRITE: upload_operation->relative_path.
      ELSE.
        WRITE: upload_operation->full_path.
      ENDIF.
*
      IF upload_operation->operation = lcl_operation=>upload_file.
        DATA: text_binary TYPE string.
        IF upload_operation->object_type = lcl_operation=>object_type_text_file.
          text_binary = text-070.
          WRITE: ' (', text_binary , ')'.
        ELSEIF upload_operation->object_type = lcl_operation=>object_type_binary_file.
          text_binary = text-071.
          WRITE: ' (', text_binary , ')'.
        ENDIF.
      ENDIF.
      IF upload_operation->message IS NOT INITIAL.
        WRITE: ' (', upload_operation->message , ')'.
      ENDIF.

    ENDLOOP.

*   ... Indicate how the items to be ignored for the upload have been determined
    WRITE: /.
    WRITE: / '* ', ui5_app->upload_ignore_message, ' *'.
    WRITE: / '* ', ui5_app->text_file_identification_msg, ' *'.
    WRITE: / '* ', ui5_app->binary_file_identification_msg, ' *'.

*   ... Indicate if adjustment of line endings has been requested
    IF adjlnnds = abap_true.
      lv_message = 'The adjustment of line endings has been requested.'(108).
      WRITE: / '* ', lv_message, ' *'.
    ENDIF.

*   Get confirmation from user
    DATA: click_here TYPE string. click_here = '[  Click here to Upload  ]'(016).
    WRITE: /.
    WRITE: /.
    WRITE: / click_here  COLOR = 5  HOTSPOT.

*   Done
    SET SCREEN 0.

  ENDIF.

* Download requested *****
  IF download EQ 'X'.

*   Initialize
    sy-title = 'Load SAPUI5 Application from the SAPUI5 ABAP Repository to the File System'(014).

*   Select source directory
    title = 'Specify Target Directory ...'(040).
    ui5_app->home_directory = file_system->select_directory( iv_title = title ).
    IF  ui5_app->home_directory IS INITIAL.
      lv_message = '* A directory for the download has not been selected. Exiting ...*'(050). WRITE: / lv_message.
      lv_last_message = '* Download canceled *'(041). EXPORT msg = lv_last_message TO MEMORY ID 'last_message'.
    ENDIF.

*   Determine download operations
    ui5_repository->determine_download_operations( iv_target_directory = ui5_app->home_directory ).
    ui5_app->conciliate_download_operations( EXPORTING iv_path = ui5_app->home_directory
                                                       iv_ignores = ui5_repository->ignores
                                             CHANGING cv_download_operations = ui5_repository->download_operations ).

*   Print outcome
*   ... List operations on file system
    DATA: the_target_directory_is TYPE string. the_target_directory_is = 'The target directory for the download is'(056).
    WRITE: AT / '* ', the_target_directory_is , '  ', ui5_app->home_directory, ' *' .
    WRITE: /.
*   ... Determine column indent on download operations
    la = strlen( text-083 ).
    lb = strlen( text-082 ).
    lc = strlen( text-007 ).
    ld = strlen( text-008 ).
    DATA: le TYPE i. le = strlen( text-080 ).
    DATA: lf TYPE i. lf = strlen( text-081 ).
    shiftright = lcl_function=>max( a = la b = lb c = lc d = ld e = le f = lf ).
    "shiftright = lcl_function=>max( a = strlen( text-083 ) b = strlen( text-082 ) c = strlen( text-007 )
    "                                d = strlen( text-008 ) e = strlen( text-080 ) f = strlen( text-081 ) ).
*   ... List download operations on directories and files
    DATA: download_operation TYPE REF TO lcl_operation.
    LOOP AT ui5_repository->download_operations INTO download_operation.
      IF     download_operation->operation = lcl_operation=>create_folder.
        WRITE: AT /(shiftright) text-083 , '  :  '. "Create Folder
      ELSEIF download_operation->operation = lcl_operation=>download_file.
        WRITE: AT /(shiftright) text-082 , '  :  '. "Download File
      ELSEIF download_operation->operation = lcl_operation=>ignore_folder.
        WRITE: AT /(shiftright) text-007 , '  :  '. "*** IGNORE ***
      ELSEIF download_operation->operation = lcl_operation=>ignore_file.
        WRITE: AT /(shiftright) text-008 , '  :  '. "*** IGNORE ***
      ELSEIF download_operation->operation = lcl_operation=>delete_folder.
        WRITE: AT /(shiftright) text-080 , '  :  '. "Delete Folder
      ELSEIF download_operation->operation = lcl_operation=>delete_file.
        WRITE: AT /(shiftright) text-081 , '  :  '. "Delete File
      ENDIF.
      IF download_operation->operation = lcl_operation=>delete_file
         OR download_operation->operation = lcl_operation=>delete_folder
         OR download_operation->operation = lcl_operation=>ignore_folder
         OR download_operation->operation = lcl_operation=>ignore_file.
        WRITE: download_operation->full_path.
      ELSE.
        WRITE: download_operation->relative_path.
      ENDIF.
*
      IF download_operation->operation = lcl_operation=>download_file.
        IF download_operation->object_type = lcl_operation=>object_type_text_file.
          text_binary = text-070.
          WRITE: ' (', text_binary , ')'.
        ELSEIF download_operation->object_type = lcl_operation=>object_type_binary_file.
          text_binary = text-071.
          WRITE: ' (', text_binary , ')'.
        ENDIF.
      ENDIF.
      IF download_operation->message IS NOT INITIAL.
        WRITE: ' (', download_operation->message , ')'.
      ENDIF.

    ENDLOOP.

*   ... Indicate how the items to be ignored for the upload have been determined
    WRITE: /.
    WRITE: / '* ', ui5_repository->ignores_identification_msg, ' *'.
    WRITE: / '* ', ui5_repository->binary_file_identification_msg, ' *'.
    WRITE: / '* ', ui5_repository->text_file_identification_msg, ' *'.

*   Get confirmation from user
    click_here = '[  Click here to Download  ]'(017).
    WRITE: /.
    WRITE: /.
    WRITE: / click_here  COLOR = 5  HOTSPOT.

*   Done
    SET SCREEN 0.


  ENDIF.

* Deletion requested *****
  IF delete EQ 'X'.

*   Initialize
    sy-title = 'Delete SAPUI5 Application'(042).

*   Message
    DATA: delete_repository TYPE string. delete_repository = 'Delete SAPUI5 Application'(042).
    WRITE: AT / '* ', delete_repository , '  ', ui5_repository->name, ' *' .

*   Get confirmation from user
    click_here = '[  Click here to Delete  ]'(018).
    WRITE: /.
    WRITE: /.
    WRITE: / click_here COLOR = 5 HOTSPOT.

*   Done
    SET SCREEN 0.

  ENDIF.
************************************************************************
AT LINE-SELECTION.

* Log is to be displayed if a log entry was created
  DATA: log_entry_created TYPE abap_bool. log_entry_created = abap_false.

* Upload *****
  IF upload EQ 'X'.

*   Create UI5 Repository if neccessary
    IF ui5_repository->already_exists = abap_false.

*     Ask for description first
      DATA: upload_parameters TYPE lcl_ui5_repository=>upload_parameters.
      TRY.
          upload_parameters = ui5_repository->get_upload_parameters( ).
        CATCH lcx_canceled.
          lv_last_message = '* Creation of UI5 repository has been canceled *'(031). EXPORT msg = lv_last_message TO MEMORY ID 'last_message'.
          LEAVE LIST-PROCESSING.
      ENDTRY.

*     Delegate ...
      DATA: lv_ex_rep_dt TYPE REF TO /ui5/cx_ui5_rep_dt.
      TRY.
          ui5_repository->api =
             /ui5/cl_ui5_rep_dt=>/ui5/if_ui5_rep_dt~create_repository(
                  iv_name = ui5_repository->name
                  iv_description = upload_parameters-description
                  iv_devclass = upload_parameters-package
                  iv_transport_request = upload_parameters-transport_request
                  iv_dialog_mode = 'X' ).

        CATCH /ui5/cx_ui5_rep_dt INTO lv_ex_rep_dt.

*         Standard message display
          IF sy-msgid IS NOT INITIAL.
            MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno DISPLAY LIKE sy-msgty.
          ENDIF.

*         Cleanup
          IF ui5_repository->api IS NOT INITIAL. CLEAR ui5_repository->api. ENDIF.

*         If any: write error text on screen
          DATA: text TYPE string.
          text = lv_ex_rep_dt->get_text( ).
          DATA(lx_ex) = lv_ex_rep_dt->previous.
          WHILE lx_ex IS BOUND.
            text = text && `: ` && lx_ex->get_text( ).
            lx_ex = lx_ex->previous.
          ENDWHILE.
          IF text IS NOT INITIAL.
            CONCATENATE '* ' text ' *' INTO text RESPECTING BLANKS.
            WRITE: / text . log_entry_created = abap_true.
          ENDIF.

*         Indicate error on initial screen
          lv_last_message = '* SAPUI5 application has not been created (successfully) *'(030).
          EXPORT msg = lv_last_message TO MEMORY ID 'last_message'.
          WRITE: / '* SAPUI5 application has not been created (successfully) *'(030).

*         Return to initial screen or display log if created
          IF log_entry_created = abap_true.
            RETURN.
          ELSE.
            LEAVE LIST-PROCESSING.
          ENDIF.

      ENDTRY.
    ELSE.

*     Ask for transport request and code page
      TRY.
          upload_parameters = ui5_repository->get_upload_parameters( iv_transport_request_only = abap_true ).
        CATCH lcx_canceled.
          lv_last_message = '* Creation of UI5 repository has been canceled *'(031). EXPORT msg = lv_last_message TO MEMORY ID 'last_message'.
          LEAVE LIST-PROCESSING.
      ENDTRY.

    ENDIF.

*   Confirm valid code page has been entered.
    IF upload_parameters-code_page_abap IS INITIAL.
      lv_last_message = text-032. "'* Upload canceled: External Code Page is invalid. You may use e.g. 'Cp1252' *'
      EXPORT msg = lv_last_message TO MEMORY ID 'last_message'.
      LEAVE LIST-PROCESSING.
    ENDIF.

*   Do the upload
    ui5_repository->api->lock( ).

*   . Loop at each operation
*     and if requested ...
    LOOP AT ui5_app->upload_operations INTO upload_operation.

*     Create folder
      IF upload_operation->operation = lcl_operation=>create_folder.
        TRY.
            ui5_repository->api->create_folder( iv_path = upload_operation->relative_path
                                                iv_transport_request = upload_parameters-transport_request ).
          CATCH /ui5/cx_ui5_rep_dt.
            log_entry_created = abap_true.
            lv_message = '* Warning: Folder % has not been created *'(054).
            REPLACE '%' IN lv_message WITH upload_operation->relative_path.
            WRITE: / lv_message.
        ENDTRY.

*     Upload text or binary file
      ELSEIF upload_operation->operation = lcl_operation=>upload_file
             AND (    upload_operation->object_type = lcl_operation=>object_type_text_file
                   OR upload_operation->object_type = lcl_operation=>object_type_binary_file ).
        TRY.

*           Read file from file system
            DATA: file_content                   TYPE xstring,
                  file_content_as_string         TYPE string,
                  file_content_as_string_windows TYPE string.
            DATA: upload_operation_is_binary TYPE abap_bool. upload_operation_is_binary = upload_operation->is_binary( ).
            file_content = file_system->read_file( iv_file_path = upload_operation->full_path
                                                   iv_file_is_binary = upload_operation_is_binary
                                                   iv_code_page_abap = upload_parameters-code_page_abap ).
            "file_content = file_system->read_file( iv_file_path = upload_operation->full_path
            "                                       iv_file_is_binary = upload_operation->is_binary( )
            "                                       iv_code_page_abap = upload_parameters-code_page_abap ).

*           Adjust line endings for text files if requested
            IF upload_operation->object_type = lcl_operation=>object_type_text_file
               AND adjlnnds = abap_true.
              TRY.
                  DATA: code_page_java TYPE string.
                  code_page_java = upload_parameters-code_page_java.
                  file_content_as_string =
                      /ui5/cl_ui5_rep_utility=>convert_xstring_2_string( iv_xstring = file_content
                                                                         iv_code_page = code_page_java ).
                  file_content_as_string_windows =
                      lcl_function=>adjust_line_endings( iv_string = file_content_as_string ).
                  file_content =
                      /ui5/cl_ui5_rep_utility=>convert_string_2_xstring( iv_string = file_content_as_string_windows
                                                                         iv_code_page = code_page_java ).
*                 Indicate conversion happened
                  IF ( file_content_as_string <> file_content_as_string_windows ).
                    lv_message = '* Info: Line endings have been adjusted in file %. *'(109).
                    CONCATENATE '* ' lv_message ' *' INTO lv_message RESPECTING BLANKS.
                    REPLACE '%' IN lv_message WITH upload_operation->relative_path.
                    WRITE: / lv_message.
                    log_entry_created = abap_true.
                  ENDIF.
                CATCH /ui5/cx_ui5_rep_dt.
                CATCH cx_sy_conversion_error.
                  lv_message = 'Warning: Unable to adjust line endings in text file %.'(107).
                  CONCATENATE '* ' lv_message ' *' INTO lv_message RESPECTING BLANKS.
                  REPLACE '%' IN lv_message WITH upload_operation->relative_path.
                  WRITE: / lv_message.
                  log_entry_created = abap_true.
              ENDTRY.
            ENDIF.

*           Upload content into ui5 repository
            DATA: mime_type TYPE string. mime_type = ui5_repository->get_mime_type_for_upload( upload_operation ).
            upload_operation_is_binary = upload_operation->is_binary( ).
            TRY.
                CALL METHOD ui5_repository->api->put_file
                  EXPORTING
                    iv_path              = upload_operation->relative_path
                    iv_transport_request = upload_parameters-transport_request
                    iv_file_content      = file_content
                    iv_mime_type         = mime_type     "ui5_repository->get_mime_type_for_upload( upload_operation )
                    iv_code_page         = upload_parameters-code_page_java
                    iv_is_binary         = upload_operation_is_binary.   "upload_operation->is_binary( ).
              CATCH /ui5/cx_ui5_rep_dt INTO lv_ex_rep_dt.

*               Write error message for UI5 repository problems
                text = lv_ex_rep_dt->get_text( ).
                lx_ex = lv_ex_rep_dt->previous.
                WHILE lx_ex IS BOUND.
                  text = text && `: ` && lx_ex->get_text( ).
                  lx_ex = lx_ex->previous.
                ENDWHILE.
                CONCATENATE '* ' text ' *' INTO lv_message RESPECTING BLANKS.
                WRITE: / lv_message.
                log_entry_created = abap_true.
                RAISE EXCEPTION TYPE lcx_exception.

            ENDTRY.

          CATCH lcx_exception.

*           Build error message
            IF upload_operation->is_binary( ) = abap_true.
              lv_message = '* Warning: Binary file % has not been uploaded *'(064).
            ELSEIF upload_operation->is_binary( ) = abap_false.
              lv_message = '* Warning: Text file % has not been uploaded *'(055).
            ENDIF.
            REPLACE '%' IN lv_message WITH upload_operation->relative_path.

*           Write it.
            WRITE: / lv_message.
            log_entry_created = abap_true.

*           Add information about ABAP error or warning message if any
            DATA: abap_message TYPE REF TO /ui5/cl_abap_message.
            abap_message = /ui5/cl_abap_message=>create_from_syst_variable( ).
            IF abap_message IS NOT INITIAL and abap_message->is_error_or_warning( ) = abap_true.
              IF abap_message->already_occurred( ) = abap_false.
                abap_message->write_info( iv_shift_right_by = 2 ).
              ELSE.
                abap_message->write_info( iv_text_line_only = abap_true iv_shift_right_by = 2 ).
              ENDIF.
            ENDIF.

        ENDTRY.

*     Delete folder in UI5 repository
      ELSEIF upload_operation->operation = lcl_operation=>delete_folder.
        TRY.
            ui5_repository->api->delete( iv_path = upload_operation->relative_path
                                         iv_transport_request = upload_parameters-transport_request ).
          CATCH /ui5/cx_ui5_rep_dt INTO lv_ex_rep_dt.
*           Write error message for UI5 repository problems
            text = lv_ex_rep_dt->get_text( ).
            CONCATENATE '* ' text ' *' INTO lv_message RESPECTING BLANKS.
            WRITE: / lv_message.
            log_entry_created = abap_true.

        ENDTRY.

*     Delete file in UI5 repository
      ELSEIF upload_operation->operation = lcl_operation=>delete_file.
        TRY.
            ui5_repository->api->delete( iv_path = upload_operation->relative_path
                                         iv_transport_request = upload_parameters-transport_request ).
          CATCH /ui5/cx_ui5_rep_dt INTO lv_ex_rep_dt.
*           Write error message for UI5 repository problems
            text = lv_ex_rep_dt->get_text( ).
            CONCATENATE '* ' text ' *' INTO lv_message RESPECTING BLANKS.
            WRITE: / lv_message.
            log_entry_created = abap_true.

        ENDTRY.

      ENDIF.

    ENDLOOP.
    ui5_repository->api->unlock( ).

*   Upload done
    WRITE: / .
    WRITE: / '* Upload finished *'(045).
    lv_last_message = '* Upload finished and SAPUI5 application index updated *'(043).
    EXPORT msg = lv_last_message TO MEMORY ID 'last_message'.


*   Recalculate application index and indicate log messages if any

*   ... Recalculate app index entry
    DATA: lr_app_index           TYPE REF TO /ui5/cl_ui5_app_index.
    DATA: lv_application         TYPE o2applname.
    DATA: lt_app_index_messages  TYPE bapiret2_t.

    lv_application = ui5rep.

    lr_app_index = /ui5/cl_ui5_app_index=>get_instance( ).

    CALL METHOD lr_app_index->recalculate_app
      EXPORTING
        iv_application = lv_application
      IMPORTING
        et_messages    = lt_app_index_messages.

*   ... Indicatge messages is any
    IF lt_app_index_messages IS NOT INITIAL.

      WRITE:/ .
      WRITE:/ .
      WRITE:/ 'The following messages have been raised when the SAPUI5 application index was updated:'(112).
      WRITE:/ .

      DATA: app_index_message TYPE bapiret2.
      LOOP AT lt_app_index_messages INTO app_index_message.
        WRITE:/ '* ', app_index_message-message.
      ENDLOOP.
      log_entry_created = abap_true.

      WRITE:/ .
      WRITE:/ 'For details see application log (transaction SLG1) in client 000 for object /UI5/APPIDX.'(113).

      lv_last_messag2 = '* Update of SAPUI5 application index raised messages *'(111).
      EXPORT msg = lv_last_messag2 TO MEMORY ID 'last_messag2'.

    ENDIF.

  ENDIF.


* Download *****
  IF download EQ 'X'.

*  Ask for code page
    TRY.
        DATA: download_parameters TYPE lcl_ui5_repository=>download_parameters.
        download_parameters = ui5_repository->get_download_parameters( ).
      CATCH lcx_canceled.
        lv_last_message = '* Download of SAPUI5 application has been canceled *'(034). EXPORT msg = lv_last_message TO MEMORY ID 'last_message'.
        LEAVE LIST-PROCESSING.
    ENDTRY.

*   Confirm valid code page has been entered.
    IF download_parameters-code_page_abap IS INITIAL.
      lv_last_message = text-033. "'* Download canceled: External Code Page is invalid. You may use e.g. 'Cp1252' *'
      EXPORT msg = lv_last_message TO MEMORY ID 'last_message'.
      LEAVE LIST-PROCESSING.
    ENDIF.

*   . Loop at each operation
*     and if requested ...
    LOOP AT ui5_repository->download_operations INTO download_operation.

*     Create folder
      IF download_operation->operation = lcl_operation=>create_folder.

        TRY.
            file_system->create_folder( download_operation->full_path ).
          CATCH lcx_exception.
            log_entry_created = abap_true.
            lv_message = '* Warning: Folder % has not been created *'(054).
            REPLACE '%' IN lv_message WITH download_operation->full_path.
            WRITE: AT / lv_message.
        ENDTRY.

*     Delete file
      ELSEIF download_operation->operation = lcl_operation=>delete_file.

        TRY.
            file_system->delete_file( download_operation->full_path ).
          CATCH lcx_exception.
            log_entry_created = abap_true.
            lv_message = '* Warning: File % has not been deleted *'(065).
            REPLACE '%' IN lv_message WITH download_operation->full_path.
            WRITE: / lv_message.
        ENDTRY.

*     Delete folder
      ELSEIF download_operation->operation = lcl_operation=>delete_folder.

        TRY.
            file_system->delete_folder( download_operation->full_path ).
          CATCH lcx_exception.
            log_entry_created = abap_true.
            lv_message = '* Warning: Folder % has not been deleted *'(057).
            REPLACE '%' IN lv_message WITH download_operation->full_path.
            WRITE: / lv_message.
        ENDTRY.

*     Download text file
      ELSEIF download_operation->operation = lcl_operation=>download_file
             AND download_operation->object_type = lcl_operation=>object_type_text_file.
        TRY.
*           Retrieve file from UI5 Repository
            TRY.
                DATA: file_content_x TYPE xstring.
                ui5_repository->api->get_file( EXPORTING iv_path          = download_operation->relative_path
                                                         iv_code_page     = download_parameters-code_page_java
                                               IMPORTING ev_file_content  = file_content_x
                                                        "ev_mime_type     =
                                                        "ev_last_modified =
                                                        "ev_etag          =
                                             ).
              CATCH /ui5/cx_ui5_rep_dt INTO lv_ex_rep_dt.
                log_entry_created = abap_true.
                text = lv_ex_rep_dt->get_text( ).
                CONCATENATE '* ' text ' *' INTO lv_message RESPECTING BLANKS.
                WRITE: / lv_message.
                lv_message = '* Warning: Text file % has not been downloaded *'(058).
                REPLACE '%' IN lv_message WITH download_operation->full_path.
                WRITE: / lv_message.
            ENDTRY.
*           Store file in file system
            lcl_file_system=>write_file( iv_file_content = file_content_x
                                         iv_file_is_binary = abap_false
                                         iv_code_page_abap = download_parameters-code_page_abap
                                         iv_file_path = download_operation->full_path ).
          CATCH lcx_exception.
            log_entry_created = abap_true.
            lv_message = '* Warning: Text file % has not been downloaded *'(058).
            REPLACE '%' IN lv_message WITH download_operation->full_path.
            WRITE: / lv_message.
        ENDTRY.

*     Download binary file
      ELSEIF download_operation->operation = lcl_operation=>download_file
             AND download_operation->object_type = lcl_operation=>object_type_binary_file.
        TRY.
*           Retrierve file from UI5 Repository
            TRY.
                ui5_repository->api->get_file( EXPORTING iv_path          = download_operation->relative_path
                                                         iv_code_page     = download_parameters-code_page_java
                                               IMPORTING ev_file_content  = file_content_x
                                                        "ev_mime_type     =
                                                        "ev_last_modified =
                                                        "ev_etag          =
                                             ).
              CATCH /ui5/cx_ui5_rep_dt .
                log_entry_created = abap_true.
                lv_message = '* Warning: Binary file % has not been downloaded *'(059).
                REPLACE '%' IN lv_message WITH download_operation->full_path.
                WRITE: / lv_message.
            ENDTRY.
*           Store file in file system
            lcl_file_system=>write_file( iv_file_content = file_content_x
                                         iv_file_is_binary = abap_true
                                         iv_file_path = download_operation->full_path ).
          CATCH lcx_exception.
            log_entry_created = abap_true.
            lv_message = '* Warning: Binary file % has not been downloaded *'(059).
            REPLACE '%' IN lv_message WITH download_operation->full_path.
            WRITE: / lv_message.
        ENDTRY.

      ENDIF.

    ENDLOOP.

*   Download done
    WRITE: / .
    WRITE: / '* Download finished *'(044).
    lv_last_message = '* Download finished *'(044). EXPORT msg = lv_last_message TO MEMORY ID 'last_message'.

  ENDIF.


* Delete Repository *****
  IF delete EQ 'X'.

*   Error message if repository does not exist
    IF ui5_repository->already_exists = abap_false.
      lv_message = '* SAPUI5 application does not exist. Deletion canceled ... *'(052). WRITE: / lv_message.
      lv_last_message = lv_message. EXPORT msg = lv_last_message TO MEMORY ID 'last_message'.
      LEAVE LIST-PROCESSING.
    ENDIF.

*   Delete
    TRY.
        /ui5/cl_ui5_rep_dt=>/ui5/if_ui5_rep_dt~delete_repository(
                                                iv_name = ui5_repository_name
                                                iv_dialog_mode = 'X' ).
      CATCH /ui5/cx_ui5_rep_dt INTO lv_ex_rep_dt.

*       Standard message display
        IF sy-msgid IS NOT INITIAL.
          MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno DISPLAY LIKE sy-msgty.
        ENDIF.

*       If any: write error text on screen
        text = lv_ex_rep_dt->get_text( ).
        lx_ex = lv_ex_rep_dt->previous.
        WHILE lx_ex IS BOUND.
          text = text && `: ` && lx_ex->get_text( ).
          lx_ex = lx_ex->previous.
        ENDWHILE.
        IF text IS NOT INITIAL.
          CONCATENATE '* ' text ' *' INTO text RESPECTING BLANKS.
          WRITE: / text . log_entry_created = abap_true.
        ENDIF.

*       Indicate error on initial screen
        lv_last_message = '* Unable to delete SAPUI5 Repository (completely). Deletion canceled ... *'(053).
        EXPORT msg = lv_last_message TO MEMORY ID 'last_message'.

*       Return to initial screen or display log if created
        IF log_entry_created = abap_true.
          RETURN.
        ELSE.
          LEAVE LIST-PROCESSING.
        ENDIF.

    ENDTRY.

*   Deletion done
    lv_last_message = '* SAPUI5 Repository deleted *'(047). EXPORT msg = lv_last_message TO MEMORY ID 'last_message'.

  ENDIF.

* Display log if needed or return directly to selection screen
  IF log_entry_created = abap_true.
    RETURN.
  ELSE.
    LEAVE LIST-PROCESSING.
  ENDIF.

************************************************************************
* Snippets
************************************************************************
  DO 1 TIMES.

*    data: exists type abap_bool.
*    exists = file_system->directory_exists( 'c:\mw\temp' ).

*    lv_message = '* ... *'. write: / lv_message.
*    lv_last_message = lv_message. export msg = lv_last_message to memory id 'last_message'.

**
*    data: go type c.
*    call function 'POPUP_TO_CONFIRM' "Standard Dialog Popup
*      exporting
*        titlebar = 'Is this ok and ...'                       " Title of dialog box
*        text_question = 'Would you like to start the upload?' " Question text in dialog box
*        text_button_1 = 'Go'(011)                             " Text on the first pushbutton
**       icon_button_1 = SPACE                                 " icon-name     Icon on first pushbutton
**       text_button_2 = 'No'(002)                             " Text on the second pushbutton
**       icon_button_2 = SPACE                                 " icon-name     Icon on second pushbutton
*        default_button = '1'                                  " Cursor position
*        display_cancel_button = 'X'                           " Button for displaying cancel pushbutton
**       userdefined_f1_help = SPACE                           " dokhl-object  User-Defined F1 Help
**       start_column = 25                                     " sy-cucol   Column in which the POPUP begins
**       start_row = 6                                         " sy-curow   Line in which the POPUP begins
**       popup_type =                                          " icon-name  Icon type
**       iv_quickinfo_button_1 = SPACE                         " text132    Quick Info on First Pushbutton
**       iv_quickinfo_button_2 = SPACE                         " text132    Quick Info on Second Pushbutton
*    importing
*      answer = go                                             " Return values: '1', '2', 'A'
**   tables
**       parameter =                 " spar          Text transfer table for parameter in text
*    exceptions
*      text_not_found = 1          "               Diagnosis text not found
*    .

  ENDDO.
************************************************************************
*&---------------------------------------------------------------------*
*&       Class ABAP_UNIT_TEST
*&---------------------------------------------------------------------*
*        Text
*----------------------------------------------------------------------*
*CLASS abap_unit_test DEFINITION FOR TESTING.
*  PUBLIC SECTION.
*    DATA l_code_page TYPE REF TO lcl_external_code_page.
*    data l_file_system type ref to lcl_file_system.
*    data l_function type ref to lcl_function.
*    data lcl_operation type ref to lcl_operation.
*    data l_ui5_local_app type ref to lcl_ui5_local_app.
*    data l_repository type ref to lcl_ui5_repository.
*    METHODS:
*      constructor,
*      run.
*ENDCLASS.               "ABAP_UNIT_TEST
*
**----------------------------------------------------------------------*
**       CLASS abap_unit_test IMPLEMENTATION
**----------------------------------------------------------------------*
**
**----------------------------------------------------------------------*
*CLASS abap_unit_test IMPLEMENTATION.
*
*  METHOD constructor.
*    create object l_code_page.
**    create object l_file_system.
*    create object l_function.
*    create object lcl_operation.
**    create object l_ui5_local_app.
**    create object l_repository.
*  ENDMETHOD.                    "constructor
*  METHOD run.
*  ENDMETHOD.                    "run
*ENDCLASS.                    "abap_unit_test IMPLEMENTATION