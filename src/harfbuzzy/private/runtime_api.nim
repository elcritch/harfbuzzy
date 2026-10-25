## Runtime variants of the upstream C APIs used by this package.
from harfbuzzy/private/native_api import nil
import harfbuzzy/private/imports
import harfbuzzy/runtime

export runtime except registerHarfbuzzImports

bindRuntimeProcs(native_api):
  HarfBuzzLibrary.Core:
    [
      hb_aat_layout_has_substitution, hb_aat_layout_has_positioning,
      hb_aat_layout_has_tracking, hb_blob_create, hb_blob_create_from_file,
      hb_blob_create_from_file_or_fail, hb_blob_create_sub_blob, hb_blob_reference,
      hb_blob_destroy, hb_blob_make_immutable, hb_blob_is_immutable, hb_blob_get_length,
      hb_blob_get_data, hb_buffer_create, hb_buffer_create_similar, hb_buffer_reset,
      hb_buffer_reference, hb_buffer_destroy, hb_buffer_set_direction,
      hb_buffer_get_direction, hb_buffer_set_script, hb_buffer_get_script,
      hb_buffer_set_language, hb_buffer_get_language, hb_buffer_set_segment_properties,
      hb_buffer_guess_segment_properties, hb_buffer_set_flags, hb_buffer_get_flags,
      hb_buffer_set_cluster_level, hb_buffer_get_cluster_level,
      hb_buffer_clear_contents, hb_buffer_add, hb_buffer_add_utf8,
      hb_buffer_add_codepoints, hb_buffer_get_length, hb_buffer_get_glyph_infos,
      hb_buffer_get_glyph_positions, hb_buffer_has_positions,
      hb_buffer_serialize_list_formats, hb_buffer_serialize_glyphs, hb_tag_from_string,
      hb_tag_to_string, hb_direction_from_string, hb_direction_to_string,
      hb_language_from_string, hb_language_to_string, hb_language_get_default,
      hb_language_matches, hb_script_from_string, hb_script_to_iso15924_tag,
      hb_script_get_horizontal_direction, hb_feature_from_string, hb_feature_to_string,
      hb_draw_funcs_set_move_to_func, hb_draw_funcs_set_line_to_func,
      hb_draw_funcs_set_quadratic_to_func, hb_draw_funcs_set_cubic_to_func,
      hb_draw_funcs_set_close_path_func, hb_draw_funcs_create, hb_draw_funcs_destroy,
      hb_draw_funcs_make_immutable, hb_face_count, hb_face_create, hb_face_get_empty,
      hb_face_reference, hb_face_destroy, hb_face_reference_table,
      hb_face_reference_blob, hb_face_get_index, hb_face_get_upem,
      hb_face_get_glyph_count, hb_font_get_h_extents, hb_font_get_v_extents,
      hb_font_get_nominal_glyph, hb_font_get_glyph_h_advance,
      hb_font_get_glyph_v_advance, hb_font_get_glyph_extents, hb_font_get_glyph,
      hb_font_get_extents_for_direction, hb_font_get_glyph_advance_for_direction,
      hb_font_draw_glyph, hb_font_create, hb_font_get_empty, hb_font_reference,
      hb_font_destroy, hb_font_get_face, hb_font_set_scale, hb_font_get_scale,
      hb_font_set_ppem, hb_font_get_ppem, hb_font_set_variations, hb_ot_font_set_funcs,
      hb_ot_layout_table_find_script, hb_ot_layout_table_get_feature_tags,
      hb_ot_layout_language_get_feature_tags, hb_ot_layout_has_substitution,
      hb_ot_layout_has_positioning, hb_set_create, hb_set_reference, hb_set_destroy,
      hb_set_clear, hb_set_is_empty, hb_set_has, hb_set_add, hb_set_add_range,
      hb_set_del, hb_set_get_population, hb_set_get_min, hb_set_get_max, hb_set_next,
      hb_shape, hb_shape_full, hb_shape_list_shapers, hb_shape_plan_create,
      hb_shape_plan_create_cached, hb_shape_plan_reference, hb_shape_plan_destroy,
      hb_shape_plan_execute, hb_shape_plan_get_shaper, hb_unicode_funcs_get_default,
      hb_unicode_script, hb_version, hb_version_string, hb_version_atleast,
    ]
  HarfBuzzLibrary.Subset:
    [
      hb_subset_input_create_or_fail, hb_subset_input_reference,
      hb_subset_input_destroy, hb_subset_input_keep_everything,
      hb_subset_input_unicode_set, hb_subset_input_glyph_set,
      hb_subset_input_pin_axis_location, hb_subset_preprocess, hb_subset_or_fail,
      hb_subset_plan_execute_or_fail, hb_subset_plan_create_or_fail,
      hb_subset_plan_destroy, hb_subset_plan_reference,
    ]
