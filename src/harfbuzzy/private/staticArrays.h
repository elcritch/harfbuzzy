#ifndef HARFBUZZY_STATIC_ARRAYS_H
#define HARFBUZZY_STATIC_ARRAYS_H

#include <hb.h>

/* Nim's cstringArray is char **. Preserve that API while explicitly adding
 * HarfBuzz's nested const qualifiers. Returned lists are borrowed/read-only. */
static inline hb_bool_t
harfbuzzy_hb_shape_full(hb_font_t *font, hb_buffer_t *buffer,
                       hb_feature_t *features, unsigned int count, char **shapers)
{
  return hb_shape_full(font, buffer, features, count,
                       (const char *const *)shapers);
}

static inline hb_shape_plan_t *
harfbuzzy_hb_shape_plan_create(hb_face_t *face, hb_segment_properties_t *props,
                              hb_feature_t *features, unsigned int count,
                              char **shapers)
{
  return hb_shape_plan_create(face, props, features, count,
                              (const char *const *)shapers);
}

static inline hb_shape_plan_t *
harfbuzzy_hb_shape_plan_create_cached(hb_face_t *face,
                                     hb_segment_properties_t *props,
                                     hb_feature_t *features, unsigned int count,
                                     char **shapers)
{
  return hb_shape_plan_create_cached(face, props, features, count,
                                     (const char *const *)shapers);
}

static inline char **harfbuzzy_hb_shape_list_shapers(void)
{
  return (char **)hb_shape_list_shapers();
}

static inline char **harfbuzzy_hb_buffer_serialize_list_formats(void)
{
  return (char **)hb_buffer_serialize_list_formats();
}

#endif
