Red [
   Title: "Basic Color Management"
   Author: "Joshua 'Skrylar' Cearley"
   Version: 0.0.1
]

; XXX this is all 8-bit color!

;; Converts an 8-bit RGB tuple to an integer. Alpha is assumed to always be 100% visibility.
rgb8-to-integer: func [
   color [tuple!]
   return: [integer!]
][
   FF000000h or
   ((to integer! color/1) << 16) or
   ((to integer! color/2) << 8) or
   (to integer! color/3)
]

;; Converts an 8-bit RGBA tuple to an integer.
rgba8-to-integer: func [
   color [tuple!]
   return: [integer!]
][
   ((to integer! color/4) << 24) or
   ((to integer! color/1) << 16) or
   ((to integer! color/2) << 8) or
   (to integer! color/3)
]

;; Converts an integer to an 8-bit RGB tuple. Alpha is assumed to always be 100% visibility.
integer-to-rgb8: func [
   color [integer!]
   return: [tuple!]
   /local ret
][
   ret: 0.0.0.0
   ret/1: (color >> 16) and 255
   ret/2: (color >> 8) and 255
   ret/3: color and 255
   ret/4: 255
   ret
]

;; Converts an integer to an 8-bit RGBA tuple.
integer-to-rgba8: func [
   color [integer!]
   return: [tuple!]
   /local ret
][
   ret: 0.0.0.0
   ret/1: (color >> 16) and 255
   ret/2: (color >> 8) and 255
   ret/3: color and 255
   ret/4: (color >> 24) and 255
   ret
]

;; Retrieves the hue of a color, given an 8-bit RGB tuple.
;; Returns the hue as a 32-bit [0, 360) floating point value.

;; XXX see if we should used fixed point arithmetic, using
;; floating point could possibly lead to colors being imprecisely
;; derped with by hardware!
rgb8-to-hue: func [
   color [tuple!]
   return: [float!]
   /local minc maxc chroma h r g b
][
   ; figure out chroma
   r: (color/1) / 255.0
   g: (color/2) / 255.0
   b: (color/3) / 255.0
   minc: min min r g b
   maxc: max max r g b
   chroma: to float! (maxc - minc)
   ; convert to hue
   h: 0
   if chroma <> 0 [
      ; M = R
      if maxc = r [h: modulo ((g - b) / chroma) 6]
      ; M = G
      if maxc = g [h: ((b - r) / chroma) + 2]
      ; M = B
      if maxc = b [h: ((r - g) / chroma) + 4]
   ]
   ; h' becomes h, then scale to fit in one byte
   (h * 60.0)
]

;; Retrieves the lightness of a color, given an 8-bit RGB tuple.
;; Returns the hue as a 32-bit [0, 1] floating point value.

;; XXX see if we should used fixed point arithmetic, using
;; floating point could possibly lead to colors being imprecisely
;; derped with by hardware!
rgb8-to-lightness: func [
   color [tuple!]
   return: [float!]
   /local minc maxc chroma r g b
][
   ; figure out chroma
   r: (color/1) / 255.0
   g: (color/2) / 255.0
   b: (color/3) / 255.0
   minc: min min r g b
   maxc: max max r g b
   (maxc + minc) * 0.5
]

;; Retrieves the lightness of a color, given an 8-bit RGB tuple.
;; Returns the hue as a 32-bit [0, 1] floating point value.

;; XXX see if we should used fixed point arithmetic, using
;; floating point could possibly lead to colors being imprecisely
;; derped with by hardware!
rgb8-to-saturation: func [
   color [tuple!]
   return: [float!]
   /local minc maxc chroma r g b lightness
][
   ; figure out chroma
   r: (color/1) / 255.0
   g: (color/2) / 255.0
   b: (color/3) / 255.0
   minc: min min r g b
   maxc: max max r g b
   chroma: to float! (maxc - minc)
   either chroma <> 0 [
      lightness: (maxc + minc) * 0.5
      chroma / (1 - absolute (2 * lightness - 1))
   ][
      0
   ]
]

;; Converts an 8-bit tuple of RGB color to an 8-bit tuple
;; of HSL values.

;; XXX see if we should used fixed point arithmetic, using
;; floating point could possibly lead to colors being imprecisely
;; derped with by hardware!
rgb8-to-hsl8: func [
   color [tuple!]
   return: [tuple!]
   /local minc maxc chroma r g b h s l ret
][
   ; figure out chroma
   r: (color/1) / 255.0
   g: (color/2) / 255.0
   b: (color/3) / 255.0
   minc: min min r g b
   maxc: max max r g b
   chroma: to float! (maxc - minc)
   ; convert to hue
   h: 0
   if chroma <> 0 [
      ; M = R
      if maxc = r [h: modulo ((g - b) / chroma) 6]
      ; M = G
      if maxc = g [h: ((b - r) / chroma) + 2]
      ; M = B
      if maxc = b [h: ((r - g) / chroma) + 4]
   ]
   ; convert to HSL
   h: (h * 60.0)
   l: (maxc + minc) * 0.5
   s: either chroma <> 0 [chroma / (1 - absolute (2 * l - 1))][0]
   ; now encode the result
   ret: 0.0.0
   ret/1: to integer! ((h / 360.0) * 255.0)
   ret/2: to integer! (s * 255.0)
   ret/3: to integer! (l * 255.0)
   ret
]

; XXX define these via parse or some smartness, instead of dopey
; copypasta.

;; Retrieves the hue of a color, given an 8-bit RGB tuple.
;; Returns the hue as an 8-bit integer.
rgb8-to-hue8: func [
   color [tuple!]
   return: [integer!]
][
   to integer! (((rgb8-to-hue color) / 360.0) * 255.0)
]

;; Retrieves the lightness of a color, given an 8-bit RGB tuple.
;; Returns the lightness as an 8-bit integer.
rgb8-to-lightness8: func [
   color [tuple!]
   return: [integer!]
][
   to integer! ((rgb8-to-lightness color) * 255.0)
]

;; Retrieves the saturation of a color, given an 8-bit RGB tuple.
;; Returns the saturation as an 8-bit integer.
rgb8-to-saturation8: func [
   color [tuple!]
   return: [integer!]
][
   to integer! ((rgb8-to-saturation color) * 255.0)
]

;; Converts an RGB tuple to an HSL tuple. Alpha channel is preserved as-is.

; test stuff
print rgb8-to-hue8 255.128.64
print rgb8-to-saturation8 255.128.64
print rgb8-to-lightness8 255.128.64

print rgb8-to-hsl8 255.128.64
