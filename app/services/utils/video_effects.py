# MoviePy imports with fallback for different versions
try:
    from moviepy.editor import Clip, vfx
except ImportError:
    try:
        from moviepy import Clip, vfx
    except ImportError:
        # Fallback for older versions
        from moviepy.video.VideoClip import Clip
        from moviepy import vfx


# FadeIn
def fadein_transition(clip: Clip, t: float) -> Clip:
    return clip.with_effects([vfx.FadeIn(t)])


# FadeOut
def fadeout_transition(clip: Clip, t: float) -> Clip:
    return clip.with_effects([vfx.FadeOut(t)])


# SlideIn
def slidein_transition(clip: Clip, t: float, side: str) -> Clip:
    return clip.with_effects([vfx.SlideIn(t, side)])


# SlideOut
def slideout_transition(clip: Clip, t: float, side: str) -> Clip:
    return clip.with_effects([vfx.SlideOut(t, side)])
