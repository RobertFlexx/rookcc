unit rcc_libc_catalog;

{$mode objfpc}{$H+}

interface

uses SysUtils, rcc_types;

type
  TLibCSymbolDescriptor = record
    Name: string;
    Category: string;
    LibraryName: string;
    DynamicallyImportable: Boolean;
  end;
  TLibCSymbolDescriptorArray = array of TLibCSymbolDescriptor;

function BuildLibCSymbolCatalog: TLibCSymbolDescriptorArray;
function FindLibCSymbol(const ACatalog: TLibCSymbolDescriptorArray;
  const AName: string; out ADescriptor: TLibCSymbolDescriptor): Boolean;
function LibCSymbolCatalogSummary(const ACatalog: TLibCSymbolDescriptorArray): string;

implementation

procedure AddSymbol(var AValues: TLibCSymbolDescriptorArray;
  const AName, ACategory, ALibrary: string; AImportable: Boolean);
var N: LongInt;
begin
  N := Length(AValues); SetLength(AValues, N + 1);
  AValues[N].Name := AName; AValues[N].Category := ACategory;
  AValues[N].LibraryName := ALibrary;
  AValues[N].DynamicallyImportable := AImportable;
end;

function BuildLibCSymbolCatalog: TLibCSymbolDescriptorArray;
begin
  Result := nil;
  AddSymbol(Result,
    'GLIBC_ABI_DT_RELR', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'GLIBC_PRIVATE', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_Exit', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_Fork', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_2_1_stderr_', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_2_1_stdin_', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_2_1_stdout_', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_adjust_column', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_adjust_wcolumn', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_default_doallocate', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_default_finish', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_default_pbackfail', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_default_uflow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_default_xsgetn', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_default_xsputn', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_do_write', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_doallocbuf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_enable_locks', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_fclose', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_fdopen', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_feof', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_ferror', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_fflush', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_fgetpos', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_fgetpos64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_fgets', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_attach', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_close', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_close_it', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_doallocate', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_finish', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_fopen', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_init', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_jumps', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_open', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_overflow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_read', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_seek', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_seekoff', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_setbuf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_stat', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_sync', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_underflow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_write', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_file_xsputn', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_flockfile', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_flush_all', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_flush_all_linebuffered', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_fopen', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_fprintf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_fputs', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_fread', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_free_backup_area', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_free_wbackup_area', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_fsetpos', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_fsetpos64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_ftell', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_ftrylockfile', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_funlockfile', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_fwrite', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_getc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_getline', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_getline_info', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_gets', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_init', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_init_marker', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_init_wmarker', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_iter_begin', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_iter_end', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_iter_file', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_iter_next', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_least_wmarker', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_link_in', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_list_all', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_list_lock', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_list_resetlock', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_list_unlock', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_marker_delta', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_marker_difference', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_padn', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_peekc_locked', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_popen', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_printf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_proc_close', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_proc_open', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_putc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_puts', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_remove_marker', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_seekmark', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_seekoff', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_seekpos', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_seekwmark', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_setb', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_setbuffer', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_setvbuf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_sgetn', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_sprintf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_sputbackc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_sputbackwc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_sscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_str_init_readonly', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_str_init_static', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_str_overflow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_str_pbackfail', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_str_seekoff', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_str_underflow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_sungetc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_sungetwc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_switch_to_get_mode', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_switch_to_main_wget_area', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_switch_to_wbackup_area', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_switch_to_wget_mode', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_un_link', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_ungetc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_unsave_markers', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_unsave_wmarkers', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_vfprintf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_vfscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_vsprintf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wdefault_doallocate', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wdefault_finish', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wdefault_pbackfail', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wdefault_uflow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wdefault_xsgetn', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wdefault_xsputn', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wdo_write', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wdoallocbuf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wfile_jumps', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wfile_overflow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wfile_seekoff', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wfile_sync', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wfile_underflow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wfile_xsputn', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wmarker_delta', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_IO_wsetb', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__abort_msg', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__adjtimex', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__after_morecore_hook', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__arch_prctl', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__argz_count', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__argz_next', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__argz_stringify', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__asprintf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__asprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__assert', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__assert_fail', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__assert_perror_fail', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__backtrace', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__backtrace_symbols', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__backtrace_symbols_fd', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__bsd_getpgrp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__bzero', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__call_tls_dtors', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__check_rhosts_file', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__chk_fail', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__clock_gettime', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__clone', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__close', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__close_nocancel', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__cmsg_nxthdr', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__confstr_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__connect', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__copy_grp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ctype32_b', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ctype32_tolower', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ctype32_toupper', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ctype_b', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ctype_b_loc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ctype_get_mb_cur_max', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ctype_init', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ctype_tolower', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ctype_tolower_loc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ctype_toupper', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ctype_toupper_loc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__curbrk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__cxa_at_quick_exit', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__cxa_atexit', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__cxa_finalize', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__cxa_thread_atexit_impl', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__cyg_profile_func_enter', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__cyg_profile_func_exit', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__daylight', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__dcgettext', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__default_morecore', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__dgettext', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__dn_comp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__dn_expand', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__dn_skipname', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__dprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__dup2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__duplocale', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__endmntent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__environ', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__errno_location', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__explicit_bzero_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fbufsize', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fcntl', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fdelt_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fdelt_warn', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fentry__', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ffs', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fgets_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fgets_unlocked_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fgetws_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fgetws_unlocked_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__file_change_detection_for_fp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__file_change_detection_for_path', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__file_change_detection_for_stat', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__file_is_unchanged', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__finite', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__finitef', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__finitel', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__flbf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fork', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fortify_fail', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fpending', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fpu_control', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fpurge', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fread_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fread_unlocked_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__freadable', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__freading', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__free_hook', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__freelocale', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fseeko64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fsetlocking', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fstat64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ftello64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fwprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fwritable', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fwriting', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fxstat', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fxstat64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fxstatat', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fxstatat64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__gconv_create_spec', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__gconv_destroy_spec', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__gconv_get_alias_db', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__gconv_get_cache', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__gconv_get_modules_db', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__gconv_open', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__gconv_transliterate', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__getauxval', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__getcwd_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__getdelim', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__getdomainname_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__getgroups_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__gethostname_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__getlogin_r_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__getmntent_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__getpagesize', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__getpgid', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__getpid', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__getrlimit', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__gets_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__gettimeofday', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__getwd_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__gmtime_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__h_errno', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__h_errno_location', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__idna_from_dns_encoding', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__idna_to_dns_encoding', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__inet6_scopeid_pton', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__inet_aton_exact', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__inet_pton_length', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__internal_endnetgrent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__internal_getnetgrent_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__internal_setnetgrent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isalnum_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isalpha_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isascii_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isblank_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__iscntrl_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isctype', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isdigit_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isgraph_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isinf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isinff', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isinfl', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__islower_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isnan', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isnanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isnanf128', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isnanl', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_fscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_fwscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_scanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_sscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_strtoimax', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_strtol', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_strtol_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_strtoll', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_strtoll_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_strtoul', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_strtoul_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_strtoull', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_strtoull_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_strtoumax', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_swscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_vfscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_vfwscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_vscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_vsscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_vswscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_vwscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_wcstoimax', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_wcstol', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_wcstol_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_wcstoll', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_wcstoll_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_wcstoul', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_wcstoul_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_wcstoull', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_wcstoull_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_wcstoumax', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc23_wscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc99_fscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc99_fwscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc99_scanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc99_sscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc99_swscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc99_vfscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc99_vfwscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc99_vscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc99_vsscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc99_vswscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc99_vwscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isoc99_wscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isprint_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ispunct_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isspace_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isupper_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__iswalnum_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__iswalpha_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__iswblank_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__iswcntrl_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__iswctype', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__iswctype_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__iswdigit_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__iswgraph_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__iswlower_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__iswprint_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__iswpunct_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__iswspace_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__iswupper_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__iswxdigit_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__isxdigit_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ivaliduser', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__key_decryptsession_pk_LOCAL', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__key_encryptsession_pk_LOCAL', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__key_gendes_LOCAL', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_alloc_buffer_alloc_array', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_alloc_buffer_allocate', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_alloc_buffer_copy_bytes', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_alloc_buffer_copy_string', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_alloc_buffer_create_failure', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_alloca_cutoff', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_allocate_once_slow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_allocate_rtsig', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_calloc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_clntudp_bufcreate', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_current_sigrtmax', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_current_sigrtmin', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_dlerror_result', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_dn_expand', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_dn_skipname', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_dynarray_at_failure', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_dynarray_emplace_enlarge', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_dynarray_finalize', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_dynarray_resize', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_dynarray_resize_clear', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_early_init', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_fatal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_fcntl64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_fork', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_free', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_freeres', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_ifunc_impl_list', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_init_first', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_mallinfo', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_malloc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_mallopt', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_memalign', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_msgrcv', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_msgsnd', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_ns_makecanon', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_ns_samename', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_pread', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_pvalloc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_pwrite', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_realloc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_reallocarray', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_res_dnok', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_res_hnok', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_res_nameinquery', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_res_queriesmatch', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_rpc_getport', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_sa_len', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_scratch_buffer_grow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_scratch_buffer_grow_preserve', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_scratch_buffer_set_array_size', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_secure_getenv', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_sigaction', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_single_threaded', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_start_main', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_system', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_unwind_link_get', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__libc_valloc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__lll_lock_wait_private', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__lll_lock_wake_private', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__longjmp_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__lseek', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__lxstat', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__lxstat64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__madvise', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__malloc_hook', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__malloc_initialize_hook', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__mbrlen', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__mbrtowc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__mbsnrtowcs_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__mbsrtowcs_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__mbstowcs_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__memalign_hook', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__memcmpeq', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__memcpy_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__memmove_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__mempcpy', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__mempcpy_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__mempcpy_small', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__memset_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__merge_grp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__mktemp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__mmap', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__monstartup', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__morecore', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__mprotect', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__mq_open_2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__munmap', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nanosleep', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__netlink_assert_response', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__newlocale', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nl_langinfo_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nptl_create_event', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nptl_death_event', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nptl_last_event', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nptl_nthreads', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nptl_rtld_global', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nptl_threads_events', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nptl_version', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ns_name_compress', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ns_name_ntop', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ns_name_pack', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ns_name_pton', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ns_name_skip', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ns_name_uncompress', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ns_name_unpack', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_configure_lookup', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_database_get', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_database_lookup', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_disable_nscd', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_files_data_endent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_files_data_open', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_files_data_put', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_files_data_setent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_files_fopen', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_group_lookup', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_group_lookup2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_hash', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_hostname_digits_dots', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_hosts_lookup', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_hosts_lookup2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_lookup', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_lookup_function', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_next', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_next2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_parse_line_result', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_passwd_lookup', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_passwd_lookup2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_readline', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__nss_services_lookup2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__obstack_printf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__obstack_vprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__open', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__open64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__open64_2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__open64_nocancel', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__open_2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__open_catalog', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__open_nocancel', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__openat64_2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__openat_2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__overflow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pipe', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__poll', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__poll_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__posix_getopt', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ppoll_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pread64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pread64_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pread64_nocancel', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pread_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__printf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__printf_fp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__profile_frequency', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__progname', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__progname_full', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_cleanup_routine', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_get_minstack', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_getspecific', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_key_create', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_keys', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_mutex_destroy', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_mutex_init', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_mutex_lock', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_mutex_trylock', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_mutex_unlock', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_mutexattr_destroy', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_mutexattr_init', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_mutexattr_settype', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_once', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_register_cancel', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_register_cancel_defer', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_rwlock_destroy', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_rwlock_init', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_rwlock_rdlock', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_rwlock_tryrdlock', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_rwlock_trywrlock', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_rwlock_unlock', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_rwlock_wrlock', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_setspecific', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_unregister_cancel', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_unregister_cancel_restore', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pthread_unwind_next', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ptsname_r_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__pwrite64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__rawmemchr', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__rcmd_errstr', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__read', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__read_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__read_nocancel', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__readlink_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__readlinkat_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__realloc_hook', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__realpath_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__recv', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__recv_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__recvfrom_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__register_atfork', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_context_hostalias', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_context_mkquery', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_context_query', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_context_search', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_context_send', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_dnok', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_get_nsaddr', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_hnok', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_iclose', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_init', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_mailok', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_mkquery', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_nclose', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_ninit', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_nmkquery', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_nopt', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_nquery', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_nquerydomain', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_nsearch', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_nsend', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_ownok', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_query', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_querydomain', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_randomid', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_search', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_send', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__res_state', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__resolv_context_get', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__resolv_context_get_override', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__resolv_context_get_preinit', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__resolv_context_put', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__resp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__rpc_thread_createerr', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__rpc_thread_svc_fdset', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__rpc_thread_svc_max_pollfd', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__rpc_thread_svc_pollfd', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sbrk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sched_cpualloc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sched_cpucount', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sched_cpufree', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sched_get_priority_max', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sched_get_priority_min', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sched_getparam', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sched_getscheduler', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sched_setscheduler', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sched_yield', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__secure_getenv', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__select', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__send', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sendmmsg', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__setmntent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__setpgid', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__shm_get_name', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sigaction', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sigaddset', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sigdelset', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sigismember', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__signbit', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__signbitf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__signbitl', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sigpause', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sigsetjmp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sigsuspend', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sigtimedwait', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__snprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__socket', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__stack_chk_fail', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__statfs', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__stpcpy', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__stpcpy_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__stpcpy_small', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__stpncpy', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__stpncpy_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strcasecmp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strcasecmp_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strcasestr', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strcat_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strcoll_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strcpy_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strcpy_small', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strcspn_c1', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strcspn_c2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strcspn_c3', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strdup', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strerror_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strfmon_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strftime_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strlcat_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strlcpy_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strncasecmp_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strncat_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strncpy_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strndup', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strpbrk_c2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strpbrk_c3', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strsep_1c', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strsep_2c', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strsep_3c', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strsep_g', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strspn_c1', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strspn_c2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strspn_c3', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtod_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtod_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtod_nan', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtof128_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtof128_nan', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtof_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtof_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtof_nan', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtok_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtok_r_1c', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtol_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtol_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtold_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtold_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtold_nan', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtoll_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtoll_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtoul_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtoul_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtoull_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strtoull_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strverscmp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__strxfrm_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__swprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sysconf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sysctl', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__syslog_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__sysv_signal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__tdelete', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__tfind', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__timezone', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__toascii_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__tolower_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__toupper_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__towctrans', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__towctrans_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__towlower_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__towupper_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__tsearch', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__ttyname_r_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__twalk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__twalk_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__tzname', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__uflow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__underflow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__uselocale', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__vasprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__vdprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__vfork', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__vfprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__vfscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__vfwprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__vprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__vsnprintf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__vsnprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__vsprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__vsscanf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__vswprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__vsyslog_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__vwprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wait', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__waitpid', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcpcpy_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcpncpy_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcrtomb_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcscasecmp_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcscat_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcscoll_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcscpy_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcsftime_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcslcat_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcslcpy_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcsncasecmp_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcsncat_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcsncpy_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcsnrtombs_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcsrtombs_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstod_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstod_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstof128_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstof_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstof_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstol_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstol_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstold_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstold_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstoll_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstoll_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstombs_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstoul_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstoul_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstoull_internal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcstoull_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wcsxfrm_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wctomb_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wctrans_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wctype_l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wmemcpy_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wmemmove_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wmempcpy_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wmemset_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__woverflow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wprintf_chk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__write', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__write_nocancel', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wuflow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__wunderflow', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__x86_get_cpuid_feature_leaf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__xmknod', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__xmknodat', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__xpg_basename', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__xpg_sigpause', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__xpg_strerror_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__xstat', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '__xstat64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_authenticate', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_environ', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_exit', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_flushlbf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_itoa_lower_digits', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_libc_intl_domainname', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_longjmp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_mcleanup', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_mcount', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nl_default_dirname', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nl_domain_bindings', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nl_msg_cat_cntr', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_dns_getcanonname_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_dns_gethostbyaddr2_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_dns_gethostbyaddr_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_dns_gethostbyname2_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_dns_gethostbyname3_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_dns_gethostbyname4_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_dns_gethostbyname_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_dns_getnetbyaddr_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_dns_getnetbyname_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_endaliasent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_endetherent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_endgrent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_endhostent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_endnetent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_endnetgrent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_endprotoent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_endpwent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_endrpcent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_endservent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_endsgent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_endspent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getaliasbyname_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getaliasent_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getetherent_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getgrent_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getgrgid_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getgrnam_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_gethostbyaddr_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_gethostbyname2_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_gethostbyname3_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_gethostbyname4_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_gethostbyname_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_gethostent_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_gethostton_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getnetbyaddr_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getnetbyname_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getnetent_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getnetgrent_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getntohost_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getprotobyname_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getprotobynumber_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getprotoent_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getpwent_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getpwnam_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getpwuid_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getrpcbyname_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getrpcbynumber_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getrpcent_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getservbyname_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getservbyport_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getservent_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getsgent_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getsgnam_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getspent_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_getspnam_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_init', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_initgroups_dyn', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_parse_etherent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_parse_grent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_parse_netent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_parse_protoent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_parse_pwent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_parse_rpcent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_parse_servent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_parse_sgent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_parse_spent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_setaliasent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_setetherent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_setgrent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_sethostent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_setnetent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_setnetgrent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_setprotoent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_setpwent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_setrpcent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_setservent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_setsgent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_files_setspent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_nss_netgroup_parseline', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_null_auth', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_obstack', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_obstack_allocated_p', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_obstack_begin', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_obstack_begin_1', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_obstack_free', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_obstack_memory_used', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_obstack_newchunk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_pthread_cleanup_pop', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_pthread_cleanup_pop_restore', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_pthread_cleanup_push', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_pthread_cleanup_push_defer', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_res', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_res_hconf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_rpc_dtablesize', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_seterr_reply', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_setjmp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_sys_errlist', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_sys_nerr', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_sys_siglist', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db___nptl_last_event', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db___nptl_nthreads', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db___nptl_rtld_global', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db___pthread_keys', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_const_thread_area', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_dtv_dtv', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_dtv_slotinfo_gen', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_dtv_slotinfo_list_len', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_dtv_slotinfo_list_next', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_dtv_slotinfo_list_slotinfo', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_dtv_slotinfo_map', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_dtv_t_counter', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_dtv_t_pointer_val', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_link_map_l_tls_modid', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_link_map_l_tls_offset', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_list_t_next', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_list_t_prev', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_cancelhandling', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_dtvp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_eventbuf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_eventbuf_eventmask', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_eventbuf_eventmask_event_bits', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_key_data_data', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_key_data_level2_data', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_key_data_seq', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_key_struct_destr', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_key_struct_seq', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_list', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_nextevent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_report_events', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_schedparam_sched_priority', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_schedpolicy', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_specific', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_start_routine', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_pthread_tid', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_rtld_global__dl_stack_used', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_rtld_global__dl_stack_user', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_rtld_global__dl_tls_dtv_slotinfo_list', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_sizeof_dtv_slotinfo', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_sizeof_dtv_slotinfo_list', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_sizeof_list_t', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_sizeof_pthread', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_sizeof_pthread_key_data', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_sizeof_pthread_key_data_level2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_sizeof_pthread_key_struct', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_sizeof_td_eventbuf_t', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_sizeof_td_thr_events_t', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_td_eventbuf_t_eventdata', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_td_eventbuf_t_eventnum', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_thread_db_td_thr_events_t_event_bits', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_tolower', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    '_toupper', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'a64l', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'abort', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'abs', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'accept', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'accept4', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'access', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'acct', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'addmntent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'addseverity', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'adjtime', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'adjtimex', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'advance', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aio_cancel', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aio_cancel64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aio_error', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aio_error64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aio_fsync', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aio_fsync64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aio_init', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aio_read', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aio_read64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aio_return', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aio_return64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aio_suspend', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aio_suspend64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aio_write', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aio_write64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'alarm', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'aligned_alloc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'alphasort', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'alphasort64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'arc4random', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'arc4random_buf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'arc4random_uniform', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'arch_prctl', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argp_err_exit_status', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argp_error', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argp_failure', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argp_help', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argp_parse', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argp_program_bug_address', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argp_program_version', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argp_program_version_hook', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argp_state_help', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argp_usage', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argz_add', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argz_add_sep', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argz_append', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argz_count', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argz_create', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argz_create_sep', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argz_delete', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argz_extract', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argz_insert', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argz_next', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argz_replace', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'argz_stringify', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'asctime', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'asctime_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'asprintf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'atof', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'atoi', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'atol', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'atoll', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'authdes_create', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'authdes_getucred', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'authdes_pk_create', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'authnone_create', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'authunix_create', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'authunix_create_default', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'backtrace', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'backtrace_symbols', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'backtrace_symbols_fd', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'basename', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'bcmp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'bcopy', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'bdflush', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'bind', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'bind_textdomain_codeset', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'bindresvport', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'bindtextdomain', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'brk', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'bsd_signal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'bsearch', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'btowc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'bzero', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'c16rtomb', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'c32rtomb', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'c8rtomb', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'call_once', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'calloc', 'memory',
    'libc.so.6', True);
  AddSymbol(Result,
    'callrpc', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'canonicalize_file_name', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'capget', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'capset', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'catclose', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'catgets', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'catopen', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'cbc_crypt', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'cfgetispeed', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'cfgetospeed', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'cfmakeraw', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'cfree', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'cfsetispeed', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'cfsetospeed', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'cfsetspeed', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'chdir', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'chflags', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'chmod', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'chown', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'chroot', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clearenv', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clearerr', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clearerr_unlocked', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clnt_broadcast', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clnt_create', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clnt_pcreateerror', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clnt_perrno', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clnt_perror', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clnt_spcreateerror', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clnt_sperrno', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clnt_sperror', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clntraw_create', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clnttcp_create', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clntudp_bufcreate', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clntudp_create', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clntunix_create', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'clock', 'time',
    'libc.so.6', True);
  AddSymbol(Result,
    'clock_adjtime', 'time',
    'libc.so.6', True);
  AddSymbol(Result,
    'clock_getcpuclockid', 'time',
    'libc.so.6', True);
  AddSymbol(Result,
    'clock_getres', 'time',
    'libc.so.6', True);
  AddSymbol(Result,
    'clock_gettime', 'time',
    'libc.so.6', True);
  AddSymbol(Result,
    'clock_nanosleep', 'time',
    'libc.so.6', True);
  AddSymbol(Result,
    'clock_settime', 'time',
    'libc.so.6', True);
  AddSymbol(Result,
    'clone', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'close', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'close_range', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'closedir', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'closefrom', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'closelog', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'cnd_broadcast', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'cnd_destroy', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'cnd_init', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'cnd_signal', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'cnd_timedwait', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'cnd_wait', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'confstr', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'connect', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'copy_file_range', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'copysign', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'copysignf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'copysignl', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'creat', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'creat64', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'create_module', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'ctermid', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'ctime', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'ctime_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'cuserid', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'daemon', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'daylight', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dcgettext', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dcngettext', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'delete_module', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'des_setparity', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dgettext', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'difftime', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dirfd', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dirname', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'div', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dl_iterate_phdr', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dladdr', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dladdr1', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dlclose', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dlerror', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dlinfo', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dlmopen', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dlopen', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dlsym', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dlvsym', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dn_comp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dn_expand', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dn_skipname', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dngettext', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dprintf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'drand48', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'drand48_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dup', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dup2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dup3', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'duplocale', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'dysize', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'eaccess', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'ecb_crypt', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'ecvt', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'ecvt_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endaliasent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endfsent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endgrent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endhostent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endmntent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endnetent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endnetgrent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endprotoent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endpwent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endrpcent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endservent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endsgent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endspent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endttyent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endusershell', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endutent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'endutxent', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'environ', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'envz_add', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'envz_entry', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'envz_get', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'envz_merge', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'envz_remove', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'envz_strip', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'epoll_create', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'epoll_create1', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'epoll_ctl', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'epoll_pwait', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'epoll_pwait2', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'epoll_wait', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'erand48', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'erand48_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'err', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'errno', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'error', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'error_at_line', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'error_message_count', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'error_one_per_line', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'error_print_progname', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'errx', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'ether_aton', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'ether_aton_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'ether_hostton', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'ether_line', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'ether_ntoa', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'ether_ntoa_r', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'ether_ntohost', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'euidaccess', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'eventfd', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'eventfd_read', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'eventfd_write', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'execl', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'execle', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'execlp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'execv', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'execve', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'execveat', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'execvp', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'execvpe', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'exit', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'explicit_bzero', 'math',
    'libc.so.6', True);
  AddSymbol(Result,
    'faccessat', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fallocate', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fallocate64', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fanotify_init', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fanotify_mark', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fattach', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fchdir', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fchflags', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fchmod', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fchmodat', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fchown', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fchownat', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fclose', 'io',
    'libc.so.6', True);


  AddSymbol(Result,
    'fdopen', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fdopendir', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'feof', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'ferror', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fflush', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fgetc', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fgetpos', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fgets', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fileno', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fopen', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fprintf', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fputc', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fputs', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fread', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'freopen', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fscanf', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fseek', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fsetpos', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fstat', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'ftell', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'fwrite', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'getc', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'getdelim', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'getenv', 'process',
    'libc.so.6', True);
  AddSymbol(Result,
    'getline', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'getopt', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'getopt_long', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'getopt_long_only', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'gets', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'gettimeofday', 'time',
    'libc.so.6', True);
  AddSymbol(Result,
    'gmtime', 'time',
    'libc.so.6', True);
  AddSymbol(Result,
    'htonl', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'htons', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'inet_addr', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'inet_ntoa', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'inet_ntop', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'inet_pton', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'ldiv', 'process',
    'libc.so.6', True);
  AddSymbol(Result,
    'listen', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'llabs', 'process',
    'libc.so.6', True);
  AddSymbol(Result,
    'lldiv', 'process',
    'libc.so.6', True);
  AddSymbol(Result,
    'localtime', 'time',
    'libc.so.6', True);
  AddSymbol(Result,
    'lstat', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'madvise', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'memchr', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'memrchr', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'mkdir', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'mkfifo', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'mktime', 'time',
    'libc.so.6', True);
  AddSymbol(Result,
    'mmap', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'mprotect', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'msync', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'munmap', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'nanosleep', 'time',
    'libc.so.6', True);
  AddSymbol(Result,
    'ntohl', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'ntohs', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'opendir', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'perror', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'poll', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'posix_fadvise', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'printf', 'misc',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_cond_broadcast', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_cond_destroy', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_cond_init', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_cond_signal', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_cond_wait', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_create', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_detach', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_equal', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_exit', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_join', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_mutex_destroy', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_mutex_init', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_mutex_lock', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_mutex_trylock', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_mutex_unlock', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'pthread_self', 'thread',
    'libc.so.6', True);
  AddSymbol(Result,
    'putc', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'putenv', 'process',
    'libc.so.6', True);
  AddSymbol(Result,
    'qsort', 'stdlib',
    'libc.so.6', True);
  AddSymbol(Result,
    'qsort_r', 'stdlib',
    'libc.so.6', True);
  AddSymbol(Result,
    'rand', 'stdlib',
    'libc.so.6', True);
  AddSymbol(Result,
    'readdir', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'realpath', 'stdlib',
    'libc.so.6', True);
  AddSymbol(Result,
    'recv', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'remove', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'rename', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'rewind', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'rewinddir', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'scanf', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'send', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'setbuf', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'setenv', 'process',
    'libc.so.6', True);
  AddSymbol(Result,
    'setvbuf', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'shutdown', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'snprintf', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'socket', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'socketpair', 'network',
    'libc.so.6', True);
  AddSymbol(Result,
    'sprintf', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'srand', 'stdlib',
    'libc.so.6', True);
  AddSymbol(Result,
    'sscanf', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'stat', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'strcasestr', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'strcat', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'strchrnul', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'strcoll', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'strcspn', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'strdup', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'strerror', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'strftime', 'time',
    'libc.so.6', True);
  AddSymbol(Result,
    'strncat', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'strndup', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'strpbrk', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'strspn', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'strstr', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'strtod', 'stdlib',
    'libc.so.6', True);
  AddSymbol(Result,
    'strtof', 'stdlib',
    'libc.so.6', True);
  AddSymbol(Result,
    'strtok', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'strtol', 'stdlib',
    'libc.so.6', True);
  AddSymbol(Result,
    'strtold', 'stdlib',
    'libc.so.6', True);
  AddSymbol(Result,
    'strtoll', 'stdlib',
    'libc.so.6', True);
  AddSymbol(Result,
    'strtoul', 'stdlib',
    'libc.so.6', True);
  AddSymbol(Result,
    'strtoull', 'stdlib',
    'libc.so.6', True);
  AddSymbol(Result,
    'strxfrm', 'string',
    'libc.so.6', True);
  AddSymbol(Result,
    'system', 'process',
    'libc.so.6', True);
  AddSymbol(Result,
    'tmpfile', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'tmpnam', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'umask', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'ungetc', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'unsetenv', 'process',
    'libc.so.6', True);
  AddSymbol(Result,
    'vasprintf', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'vdprintf', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'vfprintf', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'vprintf', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'vsnprintf', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'vsprintf', 'io',
    'libc.so.6', True);
  AddSymbol(Result,
    'wait', 'process',
    'libc.so.6', True);
  AddSymbol(Result,
    'waitpid', 'process',
    'libc.so.6', True);
  AddSymbol(Result,
    '__fpclassify', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    '__fpclassifyf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'acos', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'acosf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'asin', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'asinf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'atan', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'atanf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'atan2', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'atan2f', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'cos', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'cosf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'sin', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'sinf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'tan', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'tanf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'acosh', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'acoshf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'asinh', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'asinhf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'atanh', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'atanhf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'cosh', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'coshf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'sinh', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'sinhf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'tanh', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'tanhf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'exp', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'expf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'exp2', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'exp2f', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'expm1', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'expm1f', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'frexp', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'frexpf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'ilogb', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'ilogbf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'ldexp', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'ldexpf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'log', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'logf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'log10', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'log10f', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'log1p', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'log1pf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'log2', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'log2f', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'logb', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'logbf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'modf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'modff', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'scalbn', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'scalbnf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'scalbln', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'scalblnf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'cbrt', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'cbrtf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'fabs', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'fabsf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'hypot', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'hypotf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'pow', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'powf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'sqrt', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'sqrtf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'erf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'erff', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'erfc', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'erfcf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'lgamma', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'lgammaf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'tgamma', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'tgammaf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'ceil', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'ceilf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'floor', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'floorf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'nearbyint', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'nearbyintf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'rint', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'rintf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'lrint', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'lrintf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'llrint', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'llrintf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'round', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'roundf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'lround', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'lroundf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'llround', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'llroundf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'trunc', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'truncf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'fmod', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'fmodf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'remainder', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'remainderf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'remquo', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'remquof', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'nan', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'nanf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'nextafter', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'nextafterf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'fdim', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'fdimf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'fmax', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'fmaxf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'fmin', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'fminf', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'fma', 'math',
    'libm.so.6', True);
  AddSymbol(Result,
    'fmaf', 'math',
    'libm.so.6', True);
  AddSymbol(Result, 'fsync', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'fdatasync', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'unlink', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'rmdir', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'getcwd', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'fork', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'getuid', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'geteuid', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'getgid', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'getegid', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'pipe', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'readlink', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'isatty', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'ttyname', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'gethostname', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'getloadavg', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'sleep', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'usleep', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'sync', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'syncfs', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'mkdtemp', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'mkstemp', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'signal', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'popen', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'pclose', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'strcasecmp', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'strncasecmp', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'strtok_r', 'posix', 'libc.so.6', True);
  AddSymbol(Result, 'setlocale', 'locale', 'libc.so.6', True);
  AddSymbol(Result, 'localeconv', 'locale', 'libc.so.6', True);
  AddSymbol(Result, 'mbrtowc', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'wcrtomb', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'mbsinit', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'mbsrtowcs', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'wcsrtombs', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'wcslen', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'wcscmp', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'wcscpy', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'wcsncpy', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'wcschr', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'wcsrchr', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'wcwidth', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'wcswidth', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'iswalnum', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'iswalpha', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'iswblank', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'iswcntrl', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'iswdigit', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'iswgraph', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'iswlower', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'iswprint', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'iswpunct', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'iswspace', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'iswupper', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'iswxdigit', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'towlower', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'towupper', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'wctype', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'iswctype', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'wctrans', 'wide-character', 'libc.so.6', True);
  AddSymbol(Result, 'towctrans', 'wide-character', 'libc.so.6', True);
end;

function FindLibCSymbol(const ACatalog: TLibCSymbolDescriptorArray;
  const AName: string; out ADescriptor: TLibCSymbolDescriptor): Boolean;
var I: LongInt;
begin
  for I := 0 to High(ACatalog) do if ACatalog[I].Name = AName then
  begin ADescriptor := ACatalog[I]; Exit(True); end;
  ADescriptor.Name := ''; ADescriptor.Category := '';
  ADescriptor.LibraryName := ''; ADescriptor.DynamicallyImportable := False;
  Result := False;
end;

function LibCSymbolCatalogSummary(const ACatalog: TLibCSymbolDescriptorArray): string;
var I, Importable: LongInt;
begin
  Importable := 0;
  for I := 0 to High(ACatalog) do if ACatalog[I].DynamicallyImportable then Inc(Importable);
  Result := Format('%d hosted libc symbols (%d importable)',
    [Length(ACatalog), Importable]);
end;

end.
