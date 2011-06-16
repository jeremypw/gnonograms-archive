/* utils.c generated by valac 0.11.6, the Vala compiler
 * generated from utils.vala, do not modify */

/*  Copyright (C) 2010-2011  Jeremy Wootten
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * As a special exception, if you use inline functions from this file, this
 * file does not by itself cause the resulting executable to be covered by
 * the GNU Lesser General Public License.
 * 
 *  Author:
 * 	Jeremy Wootten <jeremwootten@gmail.com>
 */

#include <glib.h>
#include <glib-object.h>
#include <stdlib.h>
#include <string.h>
#include <gtk/gtk.h>
#include <glib/gi18n-lib.h>
#include <gio/gio.h>
#include <float.h>
#include <math.h>
#include <stdio.h>

#define _g_free0(var) (var = (g_free (var), NULL))
#define _g_object_unref0(var) ((var == NULL) ? NULL : (var = (g_object_unref (var), NULL)))
#define _g_error_free0(var) ((var == NULL) ? NULL : (var = (g_error_free (var), NULL)))

#define TYPE_CELL_STATE (cell_state_get_type ())
#define _g_string_free0(var) ((var == NULL) ? NULL : (var = (g_string_free (var, TRUE), NULL)))
#define _g_regex_unref0(var) ((var == NULL) ? NULL : (var = (g_regex_unref (var), NULL)))

typedef enum  {
	CELL_STATE_UNKNOWN,
	CELL_STATE_EMPTY,
	CELL_STATE_FILLED,
	CELL_STATE_ERROR,
	CELL_STATE_COMPLETED
} CellState;


extern gint resource_MAXROWSIZE;
extern gint resource_MAXCOLSIZE;

gchar* utils_get_stripped_basename (const gchar* path, const gchar* ext);
gchar* utils_get_string_response (const gchar* prompt);
gchar* utils_get_filename (GtkFileChooserAction action, const gchar* dialogname, gchar** filternames, int filternames_length1, gchar** filters, int filters_length1, const gchar* start_path);
gboolean utils_get_dimensions (gint* r, gint* c, gint currentr, gint currentc);
gint utils_show_dlg (const gchar* msg, GtkMessageType type, GtkButtonsType buttons);
void utils_show_info_dialog (const gchar* msg);
void utils_show_warning_dialog (const gchar* msg);
gboolean utils_show_confirm_dialog (const gchar* msg);
gchar** utils_remove_blank_lines (gchar** sa, int sa_length1, int* result_length1);
static void _vala_array_add9 (gchar*** array, int* length, int* size, gchar* value);
GDataInputStream* utils_open_datainputstream (const gchar* filename);
GType cell_state_get_type (void) G_GNUC_CONST;
CellState* utils_cellstate_array_from_string (const gchar* s, int* result_length1);
static void _vala_array_add10 (CellState** array, int* length, int* size, CellState value);
gchar* utils_gnonogram_string_from_hex_string (const gchar* s, gint pad_to_length);
gchar* utils_hex_string_from_cellstate_array (CellState* sa, int sa_length1);
gchar* utils_int2hex (gint i);
gchar* utils_convert_html (const gchar* html);
gchar* utils_string_from_cellstate_array (CellState* cs, int cs_length1);
gchar* utils_block_string_from_cellstate_array (CellState* cs, int cs_length1);
#define RESOURCE_BLOCKSEPARATOR ","
gint* utils_block_array_from_clue (const gchar* s, int* result_length1);
gint utils_blockextent_from_clue (const gchar* s);
gchar* utils_get_todays_date_string (void);
static void _vala_array_destroy (gpointer array, gint array_length, GDestroyNotify destroy_func);
static void _vala_array_free (gpointer array, gint array_length, GDestroyNotify destroy_func);
static gint _vala_array_length (gpointer array);


static gchar* string_slice (const gchar* self, glong start, glong end) {
	gchar* result = NULL;
	gint _tmp0_;
	glong string_length;
	gboolean _tmp1_ = FALSE;
	gboolean _tmp2_ = FALSE;
	gchar* _tmp3_ = NULL;
	g_return_val_if_fail (self != NULL, NULL);
	_tmp0_ = strlen (self);
	string_length = (glong) _tmp0_;
	if (start < 0) {
		start = string_length + start;
	}
	if (end < 0) {
		end = string_length + end;
	}
	if (start >= 0) {
		_tmp1_ = start <= string_length;
	} else {
		_tmp1_ = FALSE;
	}
	g_return_val_if_fail (_tmp1_, NULL);
	if (end >= 0) {
		_tmp2_ = end <= string_length;
	} else {
		_tmp2_ = FALSE;
	}
	g_return_val_if_fail (_tmp2_, NULL);
	g_return_val_if_fail (start <= end, NULL);
	_tmp3_ = g_strndup (((gchar*) self) + start, (gsize) (end - start));
	result = _tmp3_;
	return result;
}


gchar* utils_get_stripped_basename (const gchar* path, const gchar* ext) {
	gchar* result = NULL;
	gchar* _tmp0_ = NULL;
	gchar* bn;
	gboolean _tmp1_ = FALSE;
	g_return_val_if_fail (path != NULL, NULL);
	_tmp0_ = g_path_get_basename (path);
	bn = _tmp0_;
	if (ext != NULL) {
		gboolean _tmp2_;
		_tmp2_ = g_str_has_suffix (bn, ext);
		_tmp1_ = _tmp2_;
	} else {
		_tmp1_ = FALSE;
	}
	if (_tmp1_) {
		gint _tmp3_;
		gchar* _tmp4_ = NULL;
		gchar* _tmp5_;
		_tmp3_ = strlen (ext);
		_tmp4_ = string_slice (bn, (glong) 0, (glong) (-_tmp3_));
		_tmp5_ = _tmp4_;
		_g_free0 (bn);
		bn = _tmp5_;
	}
	result = bn;
	return result;
}


gchar* utils_get_string_response (const gchar* prompt) {
	gchar* result = NULL;
	const gchar* _tmp0_ = NULL;
	const gchar* _tmp1_ = NULL;
	GtkDialog* _tmp2_ = NULL;
	GtkDialog* dialog;
	GtkLabel* _tmp3_ = NULL;
	GtkLabel* label;
	GtkEntry* _tmp4_ = NULL;
	GtkEntry* entry;
	const gchar* _tmp5_ = NULL;
	gchar* _tmp6_;
	gchar* fn;
	g_return_val_if_fail (prompt != NULL, NULL);
	_tmp0_ = _ ("Ok");
	_tmp1_ = _ ("Cancel");
	_tmp2_ = (GtkDialog*) gtk_dialog_new_with_buttons (NULL, NULL, GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT, _tmp0_, GTK_RESPONSE_OK, _tmp1_, GTK_RESPONSE_CANCEL, NULL);
	dialog = g_object_ref_sink (_tmp2_);
	_tmp3_ = (GtkLabel*) gtk_label_new (prompt);
	label = g_object_ref_sink (_tmp3_);
	_tmp4_ = (GtkEntry*) gtk_entry_new ();
	entry = g_object_ref_sink (_tmp4_);
	gtk_container_add (GTK_CONTAINER (dialog->vbox), GTK_WIDGET (label));
	gtk_container_add (GTK_CONTAINER (dialog->vbox), GTK_WIDGET (entry));
	gtk_widget_show_all (GTK_WIDGET (dialog));
	gtk_dialog_run (dialog);
	_tmp5_ = gtk_entry_get_text (entry);
	_tmp6_ = g_strdup (_tmp5_);
	fn = _tmp6_;
	gtk_object_destroy (GTK_OBJECT (dialog));
	result = fn;
	_g_object_unref0 (entry);
	_g_object_unref0 (label);
	_g_object_unref0 (dialog);
	return result;
}


gchar* utils_get_filename (GtkFileChooserAction action, const gchar* dialogname, gchar** filternames, int filternames_length1, gchar** filters, int filters_length1, const gchar* start_path) {
	gchar* result = NULL;
	gchar* _tmp0_;
	gchar* button;
	GtkFileChooserDialog* _tmp5_ = NULL;
	GtkFileChooserDialog* dialog;
	gchar* temp_working_dir;
	gint _tmp12_;
	gint response;
	gchar* _tmp13_;
	gchar* fn;
	g_return_val_if_fail (dialogname != NULL, NULL);
	g_assert (filternames_length1 == filters_length1);
	_tmp0_ = g_strdup ("Error");
	button = _tmp0_;
	switch (action) {
		case GTK_FILE_CHOOSER_ACTION_OPEN:
		{
			gchar* _tmp1_;
			gchar* _tmp2_;
			_tmp1_ = g_strdup (GTK_STOCK_OPEN);
			_tmp2_ = _tmp1_;
			_g_free0 (button);
			button = _tmp2_;
			break;
		}
		case GTK_FILE_CHOOSER_ACTION_SAVE:
		{
			gchar* _tmp3_;
			gchar* _tmp4_;
			_tmp3_ = g_strdup (GTK_STOCK_SAVE);
			_tmp4_ = _tmp3_;
			_g_free0 (button);
			button = _tmp4_;
			break;
		}
		default:
		{
			break;
		}
	}
	_tmp5_ = (GtkFileChooserDialog*) gtk_file_chooser_dialog_new (dialogname, NULL, action, GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL, button, GTK_RESPONSE_ACCEPT, NULL, NULL);
	dialog = g_object_ref_sink (_tmp5_);
	{
		gint i;
		i = 0;
		{
			gboolean _tmp6_;
			_tmp6_ = TRUE;
			while (TRUE) {
				GtkFileFilter* _tmp7_ = NULL;
				GtkFileFilter* fc;
				if (!_tmp6_) {
					i++;
				}
				_tmp6_ = FALSE;
				if (!(i < filternames_length1)) {
					break;
				}
				_tmp7_ = gtk_file_filter_new ();
				fc = g_object_ref_sink (_tmp7_);
				gtk_file_filter_set_name (fc, filternames[i]);
				gtk_file_filter_add_pattern (fc, filters[i]);
				gtk_file_chooser_add_filter (GTK_FILE_CHOOSER (dialog), fc);
				_g_object_unref0 (fc);
			}
		}
	}
	temp_working_dir = NULL;
	if (start_path != NULL) {
		GFile* _tmp8_ = NULL;
		GFile* start;
		GFileType _tmp9_;
		_tmp8_ = g_file_new_for_path (start_path);
		start = _tmp8_;
		_tmp9_ = g_file_query_file_type (start, G_FILE_QUERY_INFO_NONE, NULL);
		if (_tmp9_ == G_FILE_TYPE_DIRECTORY) {
			gchar* _tmp10_ = NULL;
			gchar* _tmp11_;
			_tmp10_ = g_get_current_dir ();
			_tmp11_ = _tmp10_;
			_g_free0 (temp_working_dir);
			temp_working_dir = _tmp11_;
			g_chdir (start_path);
		}
		_g_object_unref0 (start);
	}
	_tmp12_ = gtk_dialog_run (GTK_DIALOG (dialog));
	response = _tmp12_;
	_tmp13_ = g_strdup ("");
	fn = _tmp13_;
	if (response != GTK_RESPONSE_CANCEL) {
		gchar* _tmp14_ = NULL;
		gchar* _tmp15_;
		_tmp14_ = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (dialog));
		_tmp15_ = _tmp14_;
		_g_free0 (fn);
		fn = _tmp15_;
	}
	gtk_object_destroy (GTK_OBJECT (dialog));
	if (temp_working_dir != NULL) {
		gchar* _tmp16_ = NULL;
		gchar* _tmp17_;
		_tmp16_ = g_get_current_dir ();
		_tmp17_ = _tmp16_;
		_g_free0 (temp_working_dir);
		temp_working_dir = _tmp17_;
		g_chdir (temp_working_dir);
	}
	result = fn;
	_g_free0 (temp_working_dir);
	_g_object_unref0 (dialog);
	_g_free0 (button);
	return result;
}


gboolean utils_get_dimensions (gint* r, gint* c, gint currentr, gint currentc) {
	gint _r = 0;
	gint _c = 0;
	gboolean result = FALSE;
	const gchar* _tmp0_ = NULL;
	GtkDialog* _tmp1_ = NULL;
	GtkDialog* dialog;
	GtkHBox* _tmp2_ = NULL;
	GtkHBox* hbox;
	const gchar* _tmp3_ = NULL;
	GtkLabel* _tmp4_ = NULL;
	GtkLabel* row_label;
	GtkSpinButton* _tmp5_ = NULL;
	GtkSpinButton* row_spin;
	const gchar* _tmp6_ = NULL;
	GtkLabel* _tmp7_ = NULL;
	GtkLabel* col_label;
	GtkSpinButton* _tmp8_ = NULL;
	GtkSpinButton* col_spin;
	gboolean success;
	gint _tmp9_;
	gint response;
	_tmp0_ = _ ("Adjust Size");
	_tmp1_ = (GtkDialog*) gtk_dialog_new_with_buttons (_tmp0_, NULL, GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT, GTK_STOCK_OK, GTK_RESPONSE_OK, GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL, NULL);
	dialog = g_object_ref_sink (_tmp1_);
	_tmp2_ = (GtkHBox*) gtk_hbox_new (TRUE, 6);
	hbox = g_object_ref_sink (_tmp2_);
	_tmp3_ = _ ("Rows");
	_tmp4_ = (GtkLabel*) gtk_label_new (_tmp3_);
	row_label = g_object_ref_sink (_tmp4_);
	_tmp5_ = (GtkSpinButton*) gtk_spin_button_new_with_range ((gdouble) 1, (gdouble) resource_MAXROWSIZE, (gdouble) 5);
	row_spin = g_object_ref_sink (_tmp5_);
	gtk_spin_button_set_value (row_spin, (gdouble) currentr);
	_tmp6_ = _ ("Columns");
	_tmp7_ = (GtkLabel*) gtk_label_new (_tmp6_);
	col_label = g_object_ref_sink (_tmp7_);
	_tmp8_ = (GtkSpinButton*) gtk_spin_button_new_with_range ((gdouble) 1, (gdouble) resource_MAXCOLSIZE, (gdouble) 5);
	col_spin = g_object_ref_sink (_tmp8_);
	gtk_spin_button_set_value (col_spin, (gdouble) currentc);
	gtk_container_add (GTK_CONTAINER (hbox), GTK_WIDGET (row_label));
	gtk_container_add (GTK_CONTAINER (hbox), GTK_WIDGET (row_spin));
	gtk_container_add (GTK_CONTAINER (hbox), GTK_WIDGET (col_label));
	gtk_container_add (GTK_CONTAINER (hbox), GTK_WIDGET (col_spin));
	gtk_container_add (GTK_CONTAINER (dialog->vbox), GTK_WIDGET (hbox));
	gtk_dialog_set_default_response (dialog, (gint) GTK_RESPONSE_OK);
	gtk_widget_show_all (GTK_WIDGET (dialog));
	success = FALSE;
	_tmp9_ = gtk_dialog_run (dialog);
	response = _tmp9_;
	if (response == GTK_RESPONSE_OK) {
		gint _tmp10_;
		gint _tmp11_;
		gint _tmp12_;
		gint _tmp13_;
		_tmp10_ = gtk_spin_button_get_value_as_int (row_spin);
		_tmp11_ = MAX (1, _tmp10_);
		_r = _tmp11_;
		_tmp12_ = gtk_spin_button_get_value_as_int (col_spin);
		_tmp13_ = MAX (1, _tmp12_);
		_c = _tmp13_;
		success = TRUE;
	}
	gtk_object_destroy (GTK_OBJECT (dialog));
	result = success;
	_g_object_unref0 (col_spin);
	_g_object_unref0 (col_label);
	_g_object_unref0 (row_spin);
	_g_object_unref0 (row_label);
	_g_object_unref0 (hbox);
	_g_object_unref0 (dialog);
	if (r) {
		*r = _r;
	}
	if (c) {
		*c = _c;
	}
	return result;
}


gint utils_show_dlg (const gchar* msg, GtkMessageType type, GtkButtonsType buttons) {
	gint result = 0;
	GtkMessageDialog* _tmp0_ = NULL;
	GtkMessageDialog* dialog;
	gint _tmp1_;
	gint response;
	g_return_val_if_fail (msg != NULL, 0);
	_tmp0_ = (GtkMessageDialog*) gtk_message_dialog_new (NULL, GTK_DIALOG_MODAL, type, buttons, "%s", msg);
	dialog = g_object_ref_sink (_tmp0_);
	_tmp1_ = gtk_dialog_run (GTK_DIALOG (dialog));
	response = _tmp1_;
	gtk_object_destroy (GTK_OBJECT (dialog));
	result = response;
	_g_object_unref0 (dialog);
	return result;
}


void utils_show_info_dialog (const gchar* msg) {
	g_return_if_fail (msg != NULL);
	utils_show_dlg (msg, GTK_MESSAGE_INFO, GTK_BUTTONS_CLOSE);
}


void utils_show_warning_dialog (const gchar* msg) {
	g_return_if_fail (msg != NULL);
	utils_show_dlg (msg, GTK_MESSAGE_WARNING, GTK_BUTTONS_CLOSE);
}


gboolean utils_show_confirm_dialog (const gchar* msg) {
	gboolean result = FALSE;
	gint _tmp0_;
	g_return_val_if_fail (msg != NULL, FALSE);
	_tmp0_ = utils_show_dlg (msg, GTK_MESSAGE_WARNING, GTK_BUTTONS_YES_NO);
	result = _tmp0_ == GTK_RESPONSE_YES;
	return result;
}


static gchar* string_strip (const gchar* self) {
	gchar* result = NULL;
	gchar* _tmp0_ = NULL;
	gchar* _result_;
	g_return_val_if_fail (self != NULL, NULL);
	_tmp0_ = g_strdup (self);
	_result_ = _tmp0_;
	g_strstrip (_result_);
	result = _result_;
	return result;
}


static void _vala_array_add9 (gchar*** array, int* length, int* size, gchar* value) {
	if ((*length) == (*size)) {
		*size = (*size) ? (2 * (*size)) : 4;
		*array = g_renew (gchar*, *array, (*size) + 1);
	}
	(*array)[(*length)++] = value;
	(*array)[*length] = NULL;
}


gchar** utils_remove_blank_lines (gchar** sa, int sa_length1, int* result_length1) {
	gchar** result = NULL;
	gchar** _tmp0_ = NULL;
	gchar** _result_;
	gint _result__length1;
	gint __result__size_;
	gchar** _tmp4_;
	_tmp0_ = g_new0 (gchar*, 0 + 1);
	_result_ = _tmp0_;
	_result__length1 = 0;
	__result__size_ = 0;
	{
		gint i;
		i = 0;
		{
			gboolean _tmp1_;
			_tmp1_ = TRUE;
			while (TRUE) {
				gchar* _tmp2_ = NULL;
				gchar* s;
				gchar* _tmp3_;
				if (!_tmp1_) {
					i++;
				}
				_tmp1_ = FALSE;
				if (!(i < sa_length1)) {
					break;
				}
				_tmp2_ = string_strip (sa[i]);
				s = _tmp2_;
				if (g_strcmp0 (s, "") == 0) {
					_g_free0 (s);
					continue;
				}
				_tmp3_ = g_strdup (s);
				_vala_array_add9 (&_result_, &_result__length1, &__result__size_, _tmp3_);
				_g_free0 (s);
			}
		}
	}
	_tmp4_ = _result_;
	*result_length1 = _result__length1;
	result = _tmp4_;
	return result;
}


static const gchar* string_to_string (const gchar* self) {
	const gchar* result = NULL;
	g_return_val_if_fail (self != NULL, NULL);
	result = self;
	return result;
}


GDataInputStream* utils_open_datainputstream (const gchar* filename) {
	GDataInputStream* result = NULL;
	const gchar* _tmp0_ = NULL;
	gchar* _tmp1_ = NULL;
	gchar* _tmp2_;
	GDataInputStream* stream = NULL;
	GFile* _tmp3_ = NULL;
	GFile* file;
	gboolean _tmp4_;
	GFileInputStream* _tmp7_ = NULL;
	GFileInputStream* _tmp8_;
	GFileInputStream* _tmp9_;
	GDataInputStream* _tmp10_ = NULL;
	GDataInputStream* _tmp11_;
	GError * _inner_error_ = NULL;
	g_return_val_if_fail (filename != NULL, NULL);
	_tmp0_ = string_to_string (filename);
	_tmp1_ = g_strconcat ("opening ", _tmp0_, "\n", NULL);
	_tmp2_ = _tmp1_;
	fprintf (stdout, "%s", _tmp2_);
	_g_free0 (_tmp2_);
	_tmp3_ = g_file_new_for_path (filename);
	file = _tmp3_;
	_tmp4_ = g_file_query_exists (file, NULL);
	if (!_tmp4_) {
		gchar* _tmp5_ = NULL;
		gchar* _tmp6_;
		_tmp5_ = g_file_get_path (file);
		_tmp6_ = _tmp5_;
		fprintf (stderr, "File '%s' doesn't exist.\n", _tmp6_);
		_g_free0 (_tmp6_);
		result = NULL;
		_g_object_unref0 (file);
		_g_object_unref0 (stream);
		return result;
	}
	_tmp7_ = g_file_read (file, NULL, &_inner_error_);
	_tmp8_ = _tmp7_;
	if (_inner_error_ != NULL) {
		goto __catch8_g_error;
	}
	_tmp9_ = _tmp8_;
	_tmp10_ = g_data_input_stream_new (G_INPUT_STREAM (_tmp9_));
	_tmp11_ = _tmp10_;
	_g_object_unref0 (stream);
	stream = _tmp11_;
	_g_object_unref0 (_tmp9_);
	goto __finally8;
	__catch8_g_error:
	{
		GError * e;
		e = _inner_error_;
		_inner_error_ = NULL;
		utils_show_warning_dialog (e->message);
		result = NULL;
		_g_error_free0 (e);
		_g_object_unref0 (file);
		_g_object_unref0 (stream);
		return result;
	}
	__finally8:
	if (_inner_error_ != NULL) {
		_g_object_unref0 (file);
		_g_object_unref0 (stream);
		g_critical ("file %s: line %d: uncaught error: %s (%s, %d)", __FILE__, __LINE__, _inner_error_->message, g_quark_to_string (_inner_error_->domain), _inner_error_->code);
		g_clear_error (&_inner_error_);
		return NULL;
	}
	result = stream;
	_g_object_unref0 (file);
	return result;
}


static void _vala_array_add10 (CellState** array, int* length, int* size, CellState value) {
	if ((*length) == (*size)) {
		*size = (*size) ? (2 * (*size)) : 4;
		*array = g_renew (CellState, *array, *size);
	}
	(*array)[(*length)++] = value;
}


CellState* utils_cellstate_array_from_string (const gchar* s, int* result_length1) {
	CellState* result = NULL;
	CellState* _tmp0_ = NULL;
	CellState* cs;
	gint cs_length1;
	gint _cs_size_;
	gchar** _tmp1_;
	gchar** _tmp2_ = NULL;
	gchar** _tmp3_;
	gint _tmp3__length1;
	gint _tmp4_;
	gchar** _tmp5_ = NULL;
	gchar** _tmp6_;
	gchar** data;
	gint data_length1;
	gint _data_size_;
	CellState* _tmp9_;
	g_return_val_if_fail (s != NULL, NULL);
	_tmp0_ = g_new0 (CellState, 0);
	cs = _tmp0_;
	cs_length1 = 0;
	_cs_size_ = 0;
	_tmp2_ = _tmp1_ = g_strsplit_set (s, ", ", 0);
	_tmp3_ = _tmp2_;
	_tmp3__length1 = _vala_array_length (_tmp1_);
	_tmp5_ = utils_remove_blank_lines (_tmp3_, _vala_array_length (_tmp1_), &_tmp4_);
	data = (_tmp6_ = _tmp5_, _tmp3_ = (_vala_array_free (_tmp3_, _tmp3__length1, (GDestroyNotify) g_free), NULL), _tmp6_);
	data_length1 = _tmp4_;
	_data_size_ = _tmp4_;
	{
		gint i;
		i = 0;
		{
			gboolean _tmp7_;
			_tmp7_ = TRUE;
			while (TRUE) {
				gint _tmp8_;
				if (!_tmp7_) {
					i++;
				}
				_tmp7_ = FALSE;
				if (!(i < data_length1)) {
					break;
				}
				_tmp8_ = atoi (data[i]);
				_vala_array_add10 (&cs, &cs_length1, &_cs_size_, (CellState) _tmp8_);
			}
		}
	}
	_tmp9_ = cs;
	*result_length1 = cs_length1;
	result = _tmp9_;
	data = (_vala_array_free (data, data_length1, (GDestroyNotify) g_free), NULL);
	return result;
}


static gchar string_get (const gchar* self, glong index) {
	gchar result = '\0';
	g_return_val_if_fail (self != NULL, '\0');
	result = ((gchar*) self)[index];
	return result;
}


gchar* utils_gnonogram_string_from_hex_string (const gchar* s, gint pad_to_length) {
	gchar* result = NULL;
	GString* _tmp0_ = NULL;
	GString* sb;
	gint count;
	gchar* _tmp6_;
	g_return_val_if_fail (s != NULL, NULL);
	_tmp0_ = g_string_new ("");
	sb = _tmp0_;
	count = 0;
	{
		gint i;
		i = 0;
		{
			gboolean _tmp1_;
			_tmp1_ = TRUE;
			while (TRUE) {
				gint _tmp2_;
				gchar _tmp3_;
				gchar _tmp4_;
				if (!_tmp1_) {
					i++;
				}
				_tmp1_ = FALSE;
				_tmp2_ = strlen (s);
				if (!(i < _tmp2_)) {
					break;
				}
				_tmp3_ = string_get (s, (glong) i);
				_tmp4_ = g_ascii_toupper (_tmp3_);
				switch (_tmp4_) {
					case '0':
					{
						g_string_append (sb, "1,1,1,1,");
						count = count + 4;
						break;
					}
					case '1':
					{
						g_string_append (sb, "1,1,1,2,");
						count = count + 4;
						break;
					}
					case '2':
					{
						g_string_append (sb, "1,1,2,1,");
						count = count + 4;
						break;
					}
					case '3':
					{
						g_string_append (sb, "1,1,2,2,");
						count = count + 4;
						break;
					}
					case '4':
					{
						g_string_append (sb, "1,2,1,1,");
						count = count + 4;
						break;
					}
					case '5':
					{
						g_string_append (sb, "1,2,1,2,");
						count = count + 4;
						break;
					}
					case '6':
					{
						g_string_append (sb, "1,2,2,1,");
						count = count + 4;
						break;
					}
					case '7':
					{
						g_string_append (sb, "1,2,2,2,");
						count = count + 4;
						break;
					}
					case '8':
					{
						g_string_append (sb, "2,1,1,1,");
						count = count + 4;
						break;
					}
					case '9':
					{
						g_string_append (sb, "2,1,1,2,");
						count = count + 4;
						break;
					}
					case 'A':
					{
						g_string_append (sb, "2,1,2,1,");
						count = count + 4;
						break;
					}
					case 'B':
					{
						g_string_append (sb, "2,1,2,2,");
						count = count + 4;
						break;
					}
					case 'C':
					{
						g_string_append (sb, "2,2,1,1,");
						count = count + 4;
						break;
					}
					case 'D':
					{
						g_string_append (sb, "2,2,1,2,");
						count = count + 4;
						break;
					}
					case 'E':
					{
						g_string_append (sb, "2,2,2,1,");
						count = count + 4;
						break;
					}
					case 'F':
					{
						g_string_append (sb, "2,2,2,2,");
						count = count + 4;
						break;
					}
					default:
					break;
				}
			}
		}
	}
	if (pad_to_length > 0) {
		if (count < pad_to_length) {
			{
				gint i;
				i = count;
				{
					gboolean _tmp5_;
					_tmp5_ = TRUE;
					while (TRUE) {
						if (!_tmp5_) {
							i++;
						}
						_tmp5_ = FALSE;
						if (!(i < pad_to_length)) {
							break;
						}
						g_string_prepend (sb, "1,");
					}
				}
			}
		} else {
			if (count > pad_to_length) {
				g_string_erase (sb, (gssize) 0, (gssize) ((count - pad_to_length) * 2));
			}
		}
	}
	_tmp6_ = g_strdup (sb->str);
	result = _tmp6_;
	_g_string_free0 (sb);
	return result;
}


gchar* utils_hex_string_from_cellstate_array (CellState* sa, int sa_length1) {
	gchar* result = NULL;
	GString* _tmp0_ = NULL;
	GString* sb;
	gint length;
	gint e;
	gint m;
	gint count;
	gchar* _tmp5_;
	_tmp0_ = g_string_new ("");
	sb = _tmp0_;
	length = sa_length1;
	e = 0;
	m = 1;
	count = 0;
	{
		gint i;
		i = length - 1;
		{
			gboolean _tmp1_;
			_tmp1_ = TRUE;
			while (TRUE) {
				gboolean _tmp2_ = FALSE;
				if (!_tmp1_) {
					i--;
				}
				_tmp1_ = FALSE;
				if (!(i >= 0)) {
					break;
				}
				count++;
				e = e + ((((gint) sa[i]) - 1) * m);
				m = m * 2;
				if (count == 4) {
					_tmp2_ = TRUE;
				} else {
					_tmp2_ = i == 0;
				}
				if (_tmp2_) {
					gchar* _tmp3_ = NULL;
					gchar* _tmp4_;
					_tmp3_ = utils_int2hex (e);
					_tmp4_ = _tmp3_;
					g_string_prepend (sb, _tmp4_);
					_g_free0 (_tmp4_);
					count = 0;
					m = 1;
					e = 0;
				}
			}
		}
	}
	_tmp5_ = g_strdup (sb->str);
	result = _tmp5_;
	_g_string_free0 (sb);
	return result;
}


gchar* utils_int2hex (gint i) {
	gchar* result = NULL;
	gchar* _tmp2_;
	gchar* _tmp3_;
	gchar* _tmp4_;
	gchar* _tmp5_;
	gchar* _tmp6_;
	gchar* _tmp7_;
	gchar** _tmp8_ = NULL;
	gchar** l;
	gint l_length1;
	gint _l_size_;
	gchar* _tmp9_;
	if (i <= 9) {
		gchar* _tmp0_ = NULL;
		_tmp0_ = g_strdup_printf ("%i", i);
		result = _tmp0_;
		return result;
	}
	if (i > 15) {
		gchar* _tmp1_;
		_tmp1_ = g_strdup ("X");
		result = _tmp1_;
		return result;
	}
	i = i - 10;
	_tmp2_ = g_strdup ("A");
	_tmp3_ = g_strdup ("B");
	_tmp4_ = g_strdup ("C");
	_tmp5_ = g_strdup ("D");
	_tmp6_ = g_strdup ("E");
	_tmp7_ = g_strdup ("F");
	_tmp8_ = g_new0 (gchar*, 6 + 1);
	_tmp8_[0] = _tmp2_;
	_tmp8_[1] = _tmp3_;
	_tmp8_[2] = _tmp4_;
	_tmp8_[3] = _tmp5_;
	_tmp8_[4] = _tmp6_;
	_tmp8_[5] = _tmp7_;
	l = _tmp8_;
	l_length1 = 6;
	_l_size_ = 6;
	_tmp9_ = g_strdup (l[i]);
	result = _tmp9_;
	l = (_vala_array_free (l, l_length1, (GDestroyNotify) g_free), NULL);
	return result;
}


gchar* utils_convert_html (const gchar* html) {
	gchar* result = NULL;
	GRegex* _tmp1_ = NULL;
	GRegex* regex;
	gchar** _tmp2_;
	gchar** _tmp3_ = NULL;
	gchar** s;
	gint s_length1;
	gint _s_size_;
	gchar* _tmp9_;
	GError * _inner_error_ = NULL;
	if (html == NULL) {
		gchar* _tmp0_;
		_tmp0_ = g_strdup ("");
		result = _tmp0_;
		return result;
	}
	_tmp1_ = g_regex_new ("&#([0-9]+);", 0, 0, &_inner_error_);
	regex = _tmp1_;
	if (_inner_error_ != NULL) {
		if (_inner_error_->domain == G_REGEX_ERROR) {
			goto __catch9_g_regex_error;
		}
		g_critical ("file %s: line %d: unexpected error: %s (%s, %d)", __FILE__, __LINE__, _inner_error_->message, g_quark_to_string (_inner_error_->domain), _inner_error_->code);
		g_clear_error (&_inner_error_);
		return NULL;
	}
	_tmp3_ = _tmp2_ = g_regex_split (regex, html, 0);
	s = _tmp3_;
	s_length1 = _vala_array_length (_tmp2_);
	_s_size_ = _vala_array_length (_tmp2_);
	if (s_length1 > 1) {
		GString* _tmp4_ = NULL;
		GString* sb;
		gchar* _tmp8_;
		_tmp4_ = g_string_new ("");
		sb = _tmp4_;
		{
			gint i;
			i = 0;
			{
				gboolean _tmp5_;
				_tmp5_ = TRUE;
				while (TRUE) {
					gint _tmp6_;
					gint u;
					gboolean _tmp7_ = FALSE;
					if (!_tmp5_) {
						i++;
					}
					_tmp5_ = FALSE;
					if (!(i < s_length1)) {
						break;
					}
					_tmp6_ = atoi (s[i]);
					u = _tmp6_;
					if (u > 31) {
						_tmp7_ = u < 65535;
					} else {
						_tmp7_ = FALSE;
					}
					if (_tmp7_) {
						g_string_append_unichar (sb, (gunichar) u);
					} else {
						if (g_strcmp0 (s[i], "") != 0) {
							g_string_append (sb, s[i]);
						}
					}
				}
			}
		}
		_tmp8_ = g_strdup (sb->str);
		result = _tmp8_;
		_g_string_free0 (sb);
		s = (_vala_array_free (s, s_length1, (GDestroyNotify) g_free), NULL);
		_g_regex_unref0 (regex);
		return result;
	}
	_tmp9_ = g_strdup (html);
	result = _tmp9_;
	s = (_vala_array_free (s, s_length1, (GDestroyNotify) g_free), NULL);
	_g_regex_unref0 (regex);
	return result;
	s = (_vala_array_free (s, s_length1, (GDestroyNotify) g_free), NULL);
	_g_regex_unref0 (regex);
	goto __finally9;
	__catch9_g_regex_error:
	{
		GError * re;
		gchar* _tmp10_;
		re = _inner_error_;
		_inner_error_ = NULL;
		utils_show_warning_dialog (re->message);
		_tmp10_ = g_strdup ("");
		result = _tmp10_;
		_g_error_free0 (re);
		return result;
	}
	__finally9:
	g_critical ("file %s: line %d: uncaught error: %s (%s, %d)", __FILE__, __LINE__, _inner_error_->message, g_quark_to_string (_inner_error_->domain), _inner_error_->code);
	g_clear_error (&_inner_error_);
	return NULL;
}


gchar* utils_string_from_cellstate_array (CellState* cs, int cs_length1) {
	gchar* result = NULL;
	GString* _tmp1_ = NULL;
	GString* sb;
	gchar* _tmp5_;
	if (cs == NULL) {
		gchar* _tmp0_;
		_tmp0_ = g_strdup ("");
		result = _tmp0_;
		return result;
	}
	_tmp1_ = g_string_new ("");
	sb = _tmp1_;
	{
		gint i;
		i = 0;
		{
			gboolean _tmp2_;
			_tmp2_ = TRUE;
			while (TRUE) {
				gchar* _tmp3_ = NULL;
				gchar* _tmp4_;
				if (!_tmp2_) {
					i++;
				}
				_tmp2_ = FALSE;
				if (!(i < cs_length1)) {
					break;
				}
				_tmp3_ = g_strdup_printf ("%i", (gint) cs[i]);
				_tmp4_ = _tmp3_;
				g_string_append (sb, _tmp4_);
				_g_free0 (_tmp4_);
				g_string_append (sb, " ");
			}
		}
	}
	_tmp5_ = g_strdup (sb->str);
	result = _tmp5_;
	_g_string_free0 (sb);
	return result;
}


gchar* utils_block_string_from_cellstate_array (CellState* cs, int cs_length1) {
	gchar* result = NULL;
	GString* _tmp0_ = NULL;
	GString* sb;
	gint count;
	gint blocks;
	gboolean counting;
	gchar* _tmp8_;
	_tmp0_ = g_string_new ("");
	sb = _tmp0_;
	count = 0;
	blocks = 0;
	counting = FALSE;
	{
		gint i;
		i = 0;
		{
			gboolean _tmp1_;
			_tmp1_ = TRUE;
			while (TRUE) {
				if (!_tmp1_) {
					i++;
				}
				_tmp1_ = FALSE;
				if (!(i < cs_length1)) {
					break;
				}
				if (cs[i] == CELL_STATE_EMPTY) {
					if (counting) {
						gchar* _tmp2_ = NULL;
						gchar* _tmp3_;
						gchar* _tmp4_;
						_tmp2_ = g_strdup_printf ("%i", count);
						_tmp3_ = _tmp2_;
						_tmp4_ = g_strconcat (_tmp3_, RESOURCE_BLOCKSEPARATOR, NULL);
						g_string_append (sb, _tmp4_);
						_g_free0 (_tmp4_);
						_g_free0 (_tmp3_);
						counting = FALSE;
						count = 0;
						blocks++;
					}
				} else {
					if (cs[i] == CELL_STATE_FILLED) {
						counting = TRUE;
						count++;
					} else {
						fprintf (stdout, "Error in block string from cellstate array - Cellstate UNKNOWN OR IN E" \
"RROR\n");
						break;
					}
				}
			}
		}
	}
	if (counting) {
		gchar* _tmp5_ = NULL;
		gchar* _tmp6_;
		gchar* _tmp7_;
		_tmp5_ = g_strdup_printf ("%i", count);
		_tmp6_ = _tmp5_;
		_tmp7_ = g_strconcat (_tmp6_, RESOURCE_BLOCKSEPARATOR, NULL);
		g_string_append (sb, _tmp7_);
		_g_free0 (_tmp7_);
		_g_free0 (_tmp6_);
		blocks++;
	}
	if (blocks == 0) {
		g_string_append (sb, "0");
	} else {
		g_string_truncate (sb, (gsize) (sb->len - 1));
	}
	_tmp8_ = g_strdup (sb->str);
	result = _tmp8_;
	_g_string_free0 (sb);
	return result;
}


gint* utils_block_array_from_clue (const gchar* s, int* result_length1) {
	gint* result = NULL;
	gchar** _tmp0_;
	gchar** _tmp1_ = NULL;
	gchar** _tmp2_;
	gint _tmp2__length1;
	gint _tmp3_;
	gchar** _tmp4_ = NULL;
	gchar** _tmp5_;
	gchar** clues;
	gint clues_length1;
	gint _clues_size_;
	gint* _tmp6_ = NULL;
	gint* blocks;
	gint blocks_length1;
	gint _blocks_size_;
	gint* _tmp9_;
	g_return_val_if_fail (s != NULL, NULL);
	_tmp1_ = _tmp0_ = g_strsplit_set (s, ", ", 0);
	_tmp2_ = _tmp1_;
	_tmp2__length1 = _vala_array_length (_tmp0_);
	_tmp4_ = utils_remove_blank_lines (_tmp2_, _vala_array_length (_tmp0_), &_tmp3_);
	clues = (_tmp5_ = _tmp4_, _tmp2_ = (_vala_array_free (_tmp2_, _tmp2__length1, (GDestroyNotify) g_free), NULL), _tmp5_);
	clues_length1 = _tmp3_;
	_clues_size_ = _tmp3_;
	_tmp6_ = g_new0 (gint, clues_length1);
	blocks = _tmp6_;
	blocks_length1 = clues_length1;
	_blocks_size_ = clues_length1;
	{
		gint i;
		i = 0;
		{
			gboolean _tmp7_;
			_tmp7_ = TRUE;
			while (TRUE) {
				gint _tmp8_;
				if (!_tmp7_) {
					i++;
				}
				_tmp7_ = FALSE;
				if (!(i < clues_length1)) {
					break;
				}
				_tmp8_ = atoi (clues[i]);
				blocks[i] = _tmp8_;
			}
		}
	}
	_tmp9_ = blocks;
	*result_length1 = blocks_length1;
	result = _tmp9_;
	clues = (_vala_array_free (clues, clues_length1, (GDestroyNotify) g_free), NULL);
	return result;
}


gint utils_blockextent_from_clue (const gchar* s) {
	gint result = 0;
	gint _tmp0_;
	gint* _tmp1_ = NULL;
	gint* blocks;
	gint blocks_length1;
	gint _blocks_size_;
	gint extent;
	g_return_val_if_fail (s != NULL, 0);
	_tmp1_ = utils_block_array_from_clue (s, &_tmp0_);
	blocks = _tmp1_;
	blocks_length1 = _tmp0_;
	_blocks_size_ = _tmp0_;
	extent = 0;
	{
		gint* block_collection;
		int block_collection_length1;
		int block_it;
		block_collection = blocks;
		block_collection_length1 = blocks_length1;
		for (block_it = 0; block_it < blocks_length1; block_it = block_it + 1) {
			gint block;
			block = block_collection[block_it];
			{
				extent = extent + (block + 1);
			}
		}
	}
	extent--;
	result = extent;
	blocks = (g_free (blocks), NULL);
	return result;
}


gchar* utils_get_todays_date_string (void) {
	gchar* result = NULL;
	GTimeVal _tmp0_ = {0};
	GTimeVal t;
	gchar* _tmp1_ = NULL;
	gchar* _tmp2_;
	gchar* _tmp3_ = NULL;
	gchar* _tmp4_;
	t = (_tmp0_);
	g_get_current_time (&t);
	_tmp1_ = g_time_val_to_iso8601 (&t);
	_tmp2_ = _tmp1_;
	_tmp3_ = string_slice (_tmp2_, (glong) 0, (glong) 10);
	result = (_tmp4_ = _tmp3_, _g_free0 (_tmp2_), _tmp4_);
	return result;
}


static void _vala_array_destroy (gpointer array, gint array_length, GDestroyNotify destroy_func) {
	if ((array != NULL) && (destroy_func != NULL)) {
		int i;
		for (i = 0; i < array_length; i = i + 1) {
			if (((gpointer*) array)[i] != NULL) {
				destroy_func (((gpointer*) array)[i]);
			}
		}
	}
}


static void _vala_array_free (gpointer array, gint array_length, GDestroyNotify destroy_func) {
	_vala_array_destroy (array, array_length, destroy_func);
	g_free (array);
}


static gint _vala_array_length (gpointer array) {
	int length;
	length = 0;
	if (array) {
		while (((gpointer*) array)[length]) {
			length++;
		}
	}
	return length;
}


