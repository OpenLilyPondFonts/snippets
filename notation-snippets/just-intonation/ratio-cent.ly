\version "2.19.32"

% Maintain the "tonic", starting with a default middle c
#(define ji-tonic (ly:make-pitch 0 0 0))

% Change the tonic from which the notes are taken
jiTonic =
#(define-void-function (tonic)
   (ly:pitch?)
   (set! ji-tonic tonic))

% Maintain a current duration to be used when no duration is given
% This is extremely hacky and will only work in monophonic context
#(define ji-duration (ly:make-duration 2))

% Take a fraction and return the corresponding cent value
#(define (ratio->cent f1 f2)
   (* 1200
     (/ (log (/ f1 f2)) (log 2))))

% Take a fraction and return a list with 
% - the pitch in semitones
% - the cent deviation above or below (rounded)
#(define (ratio->step-deviation f1 f2)
   (let*
    (
      ; calculate cent value over the fundamental
      (step-cent (/ (ratio->cent f1 f2) 100.0))
      
      ; split that in the step and the cent part
      (step (inexact->exact (round step-cent)))
      (cent (inexact->exact (round (* 100 (- step-cent (floor step-cent))))))
      ; if cent > 50 flip it around to be negative
      (cent-deviation
       (if (> cent 50)
           (- cent 100)
           cent)))
    (cons step cent-deviation)))

% Map the semitone returned by ratio->step-deviation 
% to a LilyPond pitch index
#(define (semitones->pitch semitone)
   (let ((index (modulo semitone 12))
         (octave (floor (/ semitone 12))))
     (list 
      octave
      (list-ref 
       '((0 0)   ; c
          (0 1/2) ; cis
          (1 0)   ; d
          (1 1/2) ; dis
          (2 0)   ; e
          (3 0)   ; f
          (3 1/2) ; fis %  \jiPitch 2 1
  
          (4 0)   ; g
          (4 1/2) ; gis
          (5 0)   ; a
          (5 1/2) ; ais
          (6 0))   ; b      
       index))))

#(define (color-element grob color)
   (make-music
    'ContextSpeccedMusic
    'context-type
    'Bottom
    'element
    (make-music
     'OverrideProperty
     'once
     #t
     'pop-first
     #t
     'grob-value
     color
     'grob-property-path
     (list (quote color))
     'symbol
     grob)))

jiPitch =
#(define-music-function (dur ratio)
   ((ly:duration?) fraction?)
   (let*
    ((f1 (car ratio))
     (f2 (cdr ratio))
     (note (ratio->step-deviation f1 f2))
     (lily-pitch (semitones->pitch (car note)))
     (pitch-ratio 
      (ly:pitch-transpose
       (ly:make-pitch 
        (car lily-pitch)
        (car (second lily-pitch))
        (cadr (second lily-pitch)))
       ji-tonic))
     (cent (cdr note))
     (r (if (> cent 0)
            (/ cent 50.0)
            0.0))
     (b (* -1 (if (< cent 0)
                  (/ cent 50.0)
                  0.0)))
     (cent-color (list r 0.0 b)))
    (if dur (set! ji-duration dur))
    
    (make-music
     'SequentialMusic
     'elements
     (list 
;      (color-element 'Accidental cent-color)
;      (color-element 'NoteHead cent-color)
;      (color-element 'Stem cent-color)
;      (color-element 'TextScript cent-color)
      (make-music
       'NoteEvent
       'articulations
       (list (make-music
              'TextScriptEvent
              'text (format "~@f" (round cent))))
       'pitch
       pitch-ratio
       'duration
       ji-duration)))))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Here come the examples
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\layout {
  \context {
    \Voice
    \override TextScript.font-size = #-2
  }
  \context {
    \Staff
    \accidentalStyle dodecaphonic
  }
}

#(display "Display Cents within the octave")#(newline)
#(display (ratio->cent 4 3))#(newline)
#(display (ratio->cent 3 2))#(newline)
#(display (ratio->cent 9 8))#(newline)#(newline)

#(display "Display semitone index (0-11) and Cent deviation")#(newline)
#(display (ratio->step-deviation 4 2))#(newline)
#(display (ratio->step-deviation 3 2))#(newline)
#(display (ratio->step-deviation 9 8))#(newline)#(newline)

#(display "Display the corresponding LilyPond code for pitch")#(newline)
#(display (semitones->pitch 1))#(newline)
#(display (semitones->pitch 3))#(newline)
#(display (semitones->pitch 11))#(newline)
#(display (semitones->pitch 12))#(newline)
#(display (semitones->pitch -3))#(newline)


% Print the nearest pitch below the actual pitch
% and print the deviation in Cent below the staff

\markup "A kind of scale over the middle C"

{
  \jiPitch 1 10/9  
  \jiPitch 9/8  
  \jiPitch 8/7  
  \jiPitch 7/6  
  \jiPitch 6/5  
  \jiPitch 5/4
  \jiPitch 4/3
  \jiPitch 3/2
  \jiPitch 2/1
}

\markup "Overtones over different fundamentals, durations"

{

  \jiTonic f
  \jiPitch 2. 3/1
  \jiTonic c
  \jiPitch 4 4/1
  \jiTonic as,
  \jiPitch 2 5/1
  \jiTonic f,
  \jiPitch 6/1
  \jiTonic d,
  \jiPitch 7/1
  \jiTonic c,
  \jiPitch 8/1
}

\markup "Overtone scale on different fundamentals"

#(set! ji-duration (ly:make-duration 2))

scale =
#(define-music-function (pitch)(ly:pitch?)
   #{
     \jiTonic #pitch
     \jiPitch 1 1/1
     \jiPitch 2/1
     \jiPitch 3/1
     \jiPitch 4/1
     \jiPitch 5/1
     \jiPitch 6/1
     \jiPitch 7/1
     \jiPitch 8/1
   #})

{
  \clef bass
  \scale a,,
  \scale d,
  \clef treble
  \scale a
}

\markup \vspace #5
{
  \scale c
}

{
  \jiTonic d
  \jiPitch 5/2
}
