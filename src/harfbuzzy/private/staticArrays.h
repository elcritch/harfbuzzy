#ifndef HARFBUZZY_STATIC_ARRAYS_H
#define HARFBUZZY_STATIC_ARRAYS_H

#include <hb.h>

/* Nim's cstringArray is char **. Preserve that API while explicitly adding
 * HarfBuzz's nested const qualifiers. Returned lists are borrowed/read-only. */
#define harfbuzzy_hb_shape_full(font, buffer, features, count, shapers) \
  hb_shape_full(font, buffer, features, count, (const char *const *)(shapers))

#define harfbuzzy_hb_shape_plan_create(face, props, features, count, shapers) \
  hb_shape_plan_create(face, props, features, count, (const char *const *)(shapers))

#define harfbuzzy_hb_shape_plan_create_cached(face, props, features, count, shapers) \
  hb_shape_plan_create_cached(face, props, features, count, (const char *const *)(shapers))

#define harfbuzzy_hb_shape_list_shapers() \
  ((char **)hb_shape_list_shapers())

#define harfbuzzy_hb_buffer_serialize_list_formats() \
  ((char **)hb_buffer_serialize_list_formats())

#endif
