Red [
   Title: "Basic Color Management"
   Author: "Joshua 'Skrylar' Cearley"
   Version: 0.0.1
]

; algorithms from here
; https://en.wikipedia.org/wiki/HSL_and_HSV
; accessed 2015-12-18

; Performs a linear interpolation between `from-value` and `to-value`.
lerp: func [
   from-value [integer! float!]
   to-value [integer! float!]
   amount [float! percent!]
][
   from-value + ((to-value - from-value) * amount)
]

; XXX we might benefit from this
; http://lolengine.net/blog/2013/01/13/fast-rgb-to-hsv

; XXX this is all 8-bit color!

rgb8: context [
    ;; Converts an 8-bit RGB tuple to an integer. Alpha is assumed to
    ;; always be 100% visibility.
    to-integer: func [
       color [tuple!]
       return: [integer!]
    ][
       FF000000h or
       ((to integer! color/1) << 16) or
       ((to integer! color/2) << 8) or
       (to integer! color/3)
    ]

    ;; Converts an integer to an 8-bit RGB tuple. Alpha is assumed to
    ;; always be 100% visibility.
    from-integer: func [
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

    ;; Retrieves the hue of a color, given an 8-bit RGB tuple.
    ;; Returns the hue as a 32-bit [0, 360) floating point value.
    to-hue: func [
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
    to-lightness: func [
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

    ;; Retrieves the saturation of a color, as determined by the HSL model,
    ;; given an 8-bit RGB tuple. Returns the hue as a 32-bit [0, 1]
    ;; floating point value.
    to-saturation-hsl: func [
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

    ;; Converts an RGB color to an HSL color.
    to-hsl: func [r g b 'h 's 'l /local minc maxc chroma]
    [
       minc: min min r g b
       maxc: max max r g b
       chroma: to float! (maxc - minc)
       ; convert to hue
       set h 0
       if chroma <> 0 [
       	  ; M = R
       	  if maxc = r [set h (modulo ((g - b) / chroma) 6)]
       	  ; M = G
       	  if maxc = g [set h (((b - r) / chroma) + 2)]
       	  ; M = B
       	  if maxc = b [set h (((r - g) / chroma) + 4)]
       ]
       ; ; convert to HSL
       set h ((get h) * 60.0)
       set l ((maxc + minc) * 0.5)
       set s (either chroma <> 0 [chroma / (1 - absolute (2 * (get l) - 1))][0])
    ]

    ;; Converts an 8-bit tuple of RGB color to an 8-bit tuple of HSL values.
    to-hsl8: func [
       color [tuple!]
       return: [tuple!]
       /local minc maxc chroma r g b h s l ret
    ][
       ; figure out chroma
       r: (color/1) / 255.0
       g: (color/2) / 255.0
       b: (color/3) / 255.0
       ; perform conversion
       to-hsl r g b h s l
       ; now encode the result
       ret: 0.0.0
       ret/1: to integer! ((h / 360.0) * 255.0)
       ret/2: to integer! (s * 255.0)
       ret/3: to integer! (l * 255.0)
       ret
    ]

    ;; Converts an RGB color to an HSV color.
    to-hsv: func [r g b 'h 's 'v /local minc maxc chroma]
    [
       minc: min min r g b
       maxc: max max r g b
       chroma: to float! (maxc - minc)
       ; convert to hue
       set h 0
       either chroma <> 0 [
	  ; M = R
	  if maxc = r [set h (modulo ((g - b) / chroma) 6)]
	  ; M = G
	  if maxc = g [set h (((b - r) / chroma) + 2)]
	  ; M = B
	  if maxc = b [set h (((r - g) / chroma) + 4)]
          set s (chroma / maxc)
       ][
          set s 0
       ]
       ; convert to HSV
       set h ((get h) * 60.0)
       set v maxc
    ]

    ;; Converts an 8-bit tuple of RGB color to an 8-bit tuple of HSV values.
    to-hsv8: func [
       color [tuple!]
       return: [tuple!]
       /local minc maxc chroma r g b h s v ret
    ][
       ; figure out chroma
       r: (color/1) / 255.0
       g: (color/2) / 255.0
       b: (color/3) / 255.0
       ; perform the conversion
       to-hsv r g b h s v
       ; now encode the result
       ret: 0.0.0
       ret/1: to integer! ((h / 360.0) * 255.0)
       ret/2: to integer! (s * 255.0)
       ret/3: to integer! (v * 255.0)
       ret
    ]

    ;; Converts an HSV color to an RGB color.
    from-hsv: func [h s v 'r 'g 'b /local chroma x m hc]
    [
       ; reverse engineer chroma
       chroma: v * s
       ; reverse engineer H from H'
       hc: (h / 60.0)
       x: chroma * (1 - absolute (modulo (hc - 1) 2))
       ; make sure these are set, in case of weirdness
       set r 0
       set g 0
       set b 0
       ; figure out incomplete RGB values
       switch round/down h [
	  0 [set r chroma set g x]
	  1 [set r x set g chroma]
	  2 [set g chroma set b x]
	  3 [set g x set b chroma]
	  4 [set r x set b chroma]
	  5 [set r chroma set b x]
       ]
       ; finalize RGB values
       m: v - chroma
       set r (get r) + m
       set g (get g) + m
       set b (get b) + m
    ]

    ;; Converts an 8-bit tuple of HSV color to an 8-bit tuple
    ;; of RGB values.
    from-hsv8: func [
       color [tuple!]
       return: [tuple!]
       /local h s v x r g v ret
    ][
       ; unpack our colors
       h: ((color/1) / 255.0) * 360.0
       s: (color/2) / 255.0
       v: (color/3) / 255.0
       ; reverse engineer chroma
       chroma: v * s
       ; reverse engineer H from H'
       h: h / 60.0
       x: chroma * (1 - absolute (modulo (h - 1) 2))
       ; make sure these are set, in case of weirdness
       r: 0
       g: 0
       b: 0
       ; figure out incomplete RGB values
       switch round/down h [
	  0 [r: chroma g: x]
	  1 [r: x g: chroma]
	  2 [g: chroma b: x]
	  3 [g: x b: chroma]
	  4 [r: x b: chroma]
	  5 [r: chroma b: x]
       ]
       ; finalize RGB values
       m: v - chroma
       r: r + m
       g: g + m
       b: b + m
       ; now return the soup
       ret: 0.0.0
       ret/1: to integer! (r * 255.0)
       ret/2: to integer! (g * 255.0)
       ret/3: to integer! (b * 255.0)
       ret
    ]

    ;; Converts an 8-bit tuple of HSL color to an 8-bit tuple
    ;; of RGB values.
    from-hsl8: func [
       color [tuple!]
       return: [tuple!]
       /local h s l x r g b ret
    ][
       ; unpack our colors
       h: ((color/1) / 255.0) * 360.0
       s: (color/2) / 255.0
       l: (color/3) / 255.0
       ; reverse engineer chroma
       chroma: (1 - absolute (2 * l - 1)) * s
       ; reverse engineer H from H'
       h: h / 60.0
       x: chroma * (1 - absolute (modulo (h - 1) 2))
       ; make sure these are set, in case of weirdness
       r: 0
       g: 0
       b: 0
       ; figure out incomplete RGB values
       switch round/down h [
	  0 [r: chroma g: x]
	  1 [r: x g: chroma]
	  2 [g: chroma b: x]
	  3 [g: x b: chroma]
	  4 [r: x b: chroma]
	  5 [r: chroma b: x]
       ]
       ; finalize RGB values
       m: l - (chroma * 0.5)
       r: r + m
       g: g + m
       b: b + m
       ; now return the soup
       ret: 0.0.0
       ret/1: to integer! (r * 255.0)
       ret/2: to integer! (g * 255.0)
       ret/3: to integer! (b * 255.0)
       ret
    ]

    ;; Retrieves the hue of a color, given an 8-bit RGB tuple.
    ;; Returns the hue as an 8-bit integer.
    to-hue8: func [
       color [tuple!]
       return: [integer!]
    ][
       to integer! (((rgb8-to-hue color) / 360.0) * 255.0)
    ]

    ;; Retrieves the lightness of a color, given an 8-bit RGB tuple.
    ;; Returns the lightness as an 8-bit integer.
    to-lightness8: func [
       color [tuple!]
       return: [integer!]
    ][
       to integer! ((rgb8-to-lightness color) * 255.0)
    ]

    ;; Retrieves the saturation of a color, given an 8-bit RGB tuple.
    ;; Returns the saturation as an 8-bit integer.
    to-saturation8: func [
       color [tuple!]
       return: [integer!]
    ][
       to integer! ((rgb8-to-saturation color) * 255.0)
    ]

   mix: func [
      color [tuple!]
      target [tuple!]
      amount [float! percent!]
      /local ret
   ][
      ret: 0.0.0
      ret/1: to integer! lerp (color/1) (target/1) amount
      ret/2: to integer! lerp (color/2) (target/2) amount
      ret/3: to integer! lerp (color/3) (target/3) amount
      ret
   ]

   ;; Makes a color lighter by mixing it with White by a given `amount`.
   tint: func [
      color [tuple!]
      amount [float! percent!]
   ][
      mix color 255.255.255 amount
   ]

   shade: func [
      color [tuple!]
      amount [float! percent!]
   ][
      mix color 0.0.0 amount
   ]
]

hsl8: context [
   ;; Converts an 8-bit HSL tuple to an 8-bit RGB tuple.
   to-rgb8: :rgb8/from-hsl8

   ;; Converts an 8-bit RGB tuple to an 8-bit HSL tuple.
   from-rgb8: :rgb8/to-hsl8

   ;; Converts an 8-bit HSL tuple to an 8-bit HSV tuple.
   to-hsv8: func [
      color [tuple!]
      return: [tuple!]
   ][
      rgb8/to-hsv rgb8/from-hsl8 color
   ]

   ;; Converts an 8-bit HSV tuple to an 8-bit HSL tuple.
   from-hsv8: func [
      color [tuple!]
      return: [tuple!]
   ][
      rgb8/to-hsl rgb8/from-hsv8 color
   ]

   ;; Removes all saturation from a color.
   desaturate: func [
      color [tuple!]
      return: [tuple!]
   ][
      ret: color
      ret/2: 0
      ret
   ]

   ;; Returns the compliment of the supplied color.
   compliment: func [
      color [tuple!]
      return: [tuple!]
      /local ret
   ][
      ret: color
      ; compliments are the opposite side of the color wheel from a given color
      ret/1: to integer! round ((modulo (((color/1) / 255.0) + 180.0) 360.0) / 360.0) * 255.0
      ret
   ]

   ;; Returns either light or dark, depending on which contrasts the most with the provided base color.  Adapted from Compass' contrast-color concept.
   contrast: func [
      base [tuple!]
      light [tuple!]
      dark [tuple!]
      return: [tuple!]
   ][
      ; convert to HSV and let that module handle it
      from-hsv8 hsv8/contrast to-hsv8 base to-hsv8 light to-hsv8 dark
   ]
]

rgba8: context [
   ;; Converts an 8-bit RGBA tuple to an integer.
   to-integer: func [
      color [tuple!]
      return: [integer!]
   ][
      ((to integer! color/4) << 24) or
      ((to integer! color/1) << 16) or
      ((to integer! color/2) << 8) or
      (to integer! color/3)
   ]

   ;; Converts an integer to an 8-bit RGBA tuple.
   from-integer: func [
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

   ;; Converts an 8-bit RGB tuple to an 8-bit RGBA tuple by assigning the fourth channel to full opacity.
   from-rgba8: func [
      color [tuple!]
      return: [tuple!]
      /local ret
   ][
      ret: color
      ret/4: 255
      ret
   ]

   ;; Converts an 8-bit RGBA tuple to an 8-bit RGB tuple by stripping out the fourth channel.
   to-rgb8: func [
      color [tuple!]
      return: [tuple!]
      /local ret
   ][
      ; XXX is there a better way to do this?
      ret: 0.0.0
      ret/1: (color/1)
      ret/2: (color/2)
      ret/3: (color/3)
      ret
   ]

   ;; Makes a color some percent more transparent than it currently is.
   transparentize: func [
      color [tuple!]
      amount [float! percent!]
      /local ret
   ][
      ret: color
      ret/4: min max to integer! (color/4) * amount 0 255
      ret
   ]

   ;; Makes a color some percent more opaque than it currently is.
   opacify: func [
      color [tuple!]
      amount [float! percent!]
      /local ret
   ][
      ret: color
      if amount <> 0 [ret/4: min max to integer! (color/4) / amount 0 255]
      ret
   ]
]

hsv8: context [
   ;; Returns either light or dark, depending on which contrasts the most with the provided base color.  Adapted from Compass' contrast-color concept.
   contrast: func [
      base [tuple!]
      light [tuple!]
      dark [tuple!]
      return: [tuple!]
   ][
      either abs ((base/3) - (light/3)) > abs ((base/3) - (dark/3)) [
	 light
      ][
         dark
      ]
   ]

   ;; Removes all saturation from a color.
   desaturate: func [
      color [tuple!]
      return: [tuple!]
   ][
      ret: color
      ret/2: 0
      ret
   ]
]

; test stuff
print rgb8/to-hsl8 255.0.0
print rgb8/from-hsl8 rgb8/to-hsl8 255.0.0
print rgb8/to-hsv8 255.0.0
print rgb8/from-hsv8 rgb8/to-hsv8 255.0.0

print rgb8/from-hsl8 hsl8/compliment rgb8/to-hsl8 255.0.0

print lerp 50 100 0%
print lerp 50 100 50%
print lerp 50 100 100%
print lerp 50 100 200%

print rgb8/mix 255.0.0 0.0.0 5%
print rgb8/mix 255.0.0 0.255.0 5%

print rgba8/transparentize 255.255.255.255 50%
print rgba8/opacify 255.255.255.255 50%
