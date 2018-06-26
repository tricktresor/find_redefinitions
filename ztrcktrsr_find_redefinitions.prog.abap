REPORT ztrcktrsr_find_redefinitions.


PARAMETERS p_clas TYPE seoclsname DEFAULT 'CL_GUI_CONTROL'.
PARAMETERS p_meth TYPE seocpdname DEFAULT 'FREE'.


CLASS lcl_main DEFINITION.
  PUBLIC SECTION.
    METHODS on_double_click
                  FOR EVENT double_click OF cl_salv_events_table
      IMPORTING row column.
    METHODS docker.
    METHODS display.
    METHODS do
      IMPORTING
        i_class  TYPE clike
        i_method TYPE clike
        i_start  TYPE boolean_flg.
  PROTECTED SECTION.
    DATA mt_redef     TYPE STANDARD TABLE OF seoredef.
    DATA mo_docker    TYPE REF TO cl_gui_docking_container.
    DATA mo_editor    TYPE REF TO cl_gui_abapedit.
    METHODS display_source IMPORTING is_source TYPE seoredef.

ENDCLASS.

CLASS lcl_main IMPLEMENTATION.
  METHOD on_double_click.
    docker( ).
    DATA(redef) = mt_redef[ row ].

    display_source( redef ).

  ENDMETHOD.

  METHOD display_source.
    DATA lt_source TYPE STANDARD TABLE OF string.

    DATA(include) = cl_oo_classname_service=>get_method_include(
                      EXPORTING mtdkey = VALUE #( clsname = is_source-clsname
                                                  cpdname = is_source-mtdname ) ).
    READ REPORT include INTO lt_source.
    mo_editor->set_text( lt_source ).

  ENDMETHOD.

  METHOD docker.

    CHECK mo_docker IS INITIAL.
    mo_docker = NEW #( side = cl_gui_docking_container=>dock_at_right ratio = 50 ).
    mo_editor = NEW #( parent = mo_docker ).
    mo_editor->set_readonly_mode( 1 ).

  ENDMETHOD.

  METHOD display.

    TRY.
        " create SALV
        CALL METHOD cl_salv_table=>factory
          IMPORTING
            r_salv_table = DATA(lr_table)
          CHANGING
            t_table      = mt_redef.

        lr_table->get_functions( )->set_all( ).

        " register event DOUBLE_CLICK
        SET HANDLER on_double_click FOR lr_table->get_event( ).

        " hide columns which are not relevant
        DATA(lr_columns) = lr_table->get_columns( ).
        lr_columns->get_column( 'VERSION' )->set_technical( ).
        lr_columns->get_column( 'MTDABSTRCT' )->set_technical( ).
        lr_columns->get_column( 'MTDFINAL' )->set_technical( ).
        lr_columns->get_column( 'ATTVALUE' )->set_technical( ).
        lr_columns->get_column( 'EXPOSURE' )->set_technical( ).
        lr_table->display( ).
      CATCH cx_salv_error.
    ENDTRY.


  ENDMETHOD.


  METHOD do.

    DATA lr_class TYPE REF TO cl_oo_class.
    DATA lt_subclasses TYPE seo_relkeys.
    DATA ls_subclass   LIKE LINE OF lt_subclasses.

    TRY .
        lr_class ?= cl_oo_class=>get_instance( i_class ).

        LOOP AT lr_class->redefinitions INTO DATA(ls_redef) WHERE mtdname = i_method.
          APPEND ls_redef TO mt_redef.
        ENDLOOP.
        lt_subclasses = lr_class->get_subclasses( ).

        IF i_start = abap_true.
          " search
          LOOP AT lt_subclasses INTO ls_subclass.
            do( i_class  = ls_subclass-clsname
                i_method = i_method
                i_start  = space ).
          ENDLOOP.
        ENDIF.

      CATCH cx_class_not_existent.

    ENDTRY.

  ENDMETHOD.

ENDCLASS.



START-OF-SELECTION.

  DATA(main) = NEW lcl_main( ).
  main->do( i_class  = p_clas
            i_method = p_meth
            i_start  = abap_true ).
  main->display( ).
