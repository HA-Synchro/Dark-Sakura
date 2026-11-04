ABERRATION - low poly PSX horror creature (v1.0)
=====================================================

A chained, caged-head patient creature from Blackwood Asylum: The Rake.
Rigged on the Universal Animation Library skeleton, with 17 hand-made animations
(limping locomotion with root motion, lunge attack, falls, get-ups, crawl).


FILES
-----
  aberration.glb     glTF binary: mesh, skin, texture and all 17 clips (Godot, Unity via glTFast, three.js, Blender)
  aberration.fbx     FBX 7.4 with embedded texture and all 17 clips (Unity, Unreal)
  aberration.blend   Blender 5.2 file, texture packed, every clip stored as an Action
  aberration_body.png  512x512 albedo, nearest-neighbour filtering recommended


SPECS
-----
  Triangles   9395
  Vertices    5897
  Material    1 (albedo only, unlit-friendly)
  Texture     512x512, colour-reduced in the PSX style
  Skeleton    65 bones, Universal Animation Library naming (Quaternius UAL, CC0)
  Height      1.86 m standing (real-world scale, metres)
  Facing      +Z in Godot/glTF; -Y in Blender


ANIMATIONS (30 fps)
-------------------
  attack_ground      1.07 s
  attack_lunge       1.20 s
  crawl              2.53 s
  fall_backward      0.40 s
  fall_forward       0.53 s
  get_up_prone       2.40 s
  get_up_supine      2.60 s
  idle               5.00 s
  knee_hit_recover   1.80 s
  leg_buckle_l       0.47 s
  leg_buckle_r       0.47 s
  ragdoll_neutral    0.20 s
  roll_to_prone      1.07 s
  stumble_fall       0.53 s
  walk_fast          1.67 s
  walk_limp          2.40 s
  walk_limp_b        2.80 s

  walk_limp, walk_limp_b, walk_fast and crawl carry ROOT MOTION on the "root" bone:
  the body advances exactly as much as the planted foot (or hand) pushes back, so it
  does not slide. Use your engine's root motion (Godot: AnimationMixer.root_motion_track =
  "Skeleton3D:root"; Unity: Apply Root Motion) or ignore the root bone for in-place.

  The right leg is in a splint and does not bend: the limp is part of the character.

  fall_forward, fall_backward, stumble_fall and leg_buckle_* are the START of a fall,
  made to hand over to a ragdoll midway. ragdoll_neutral is the mid-range pose to build
  ragdoll joints from (it never plays on screen). get_up_prone and get_up_supine begin
  from lying poses, so you can blend from a ragdoll into them.


TIPS
----
  - For the PSX look: nearest filtering on the texture, low internal resolution,
    vertex lighting or unlit.
  - Godot 4: import the .glb as is. The clips keep the names above.
  - Unity: import the .fbx, set Rig to Humanoid or Generic; scale factor 1.


LICENSE
-------
  Personal and commercial use, modification and inclusion in your projects are allowed.
  Reselling or redistributing the asset files is not. Full text in LICENSE.txt.

Made by Rafael Martins for Blackwood Asylum: The Rake.
