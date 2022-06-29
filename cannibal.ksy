meta:
  id: cannibal
  file-extension: cpj
  endian: le
seq:
  - id: s_cpj_file_header
    type: s_cpj_file_header
  - id: s_cpj_chunk
    type: s_cpj_chunk_header
    repeat: eos
types:
  s_cpj_file_header:
    seq:
      - id: riff_magic
        contents: "RIFF"
      - id: len_file
        type: u4
      - id: form_magic
        contents: "CPJB"
  s_cpj_chunk_header:
    seq:
      - id: magic
        type: str
        size: 4
        encoding: ASCII
      - id: len_file
        type: u4
      - id: version
        type: u4
      - id: timestamp
        type: u4
      - id: offset_name
        type: u4
      - id: chunk
        size: len_file -12
        type:
          switch-on: magic
          cases:
            '"LODB"': s_lod_file
            '"SRFB"': s_srf_file
            '"GEOB"': s_geo_file
            '"MACB"': s_mac_file
            '"SKLB"': s_skl_file
            '"SEQB"': s_seq_file
            '"FRMB"': s_frm_file
      - id: alignment
        size: 1
        if: len_file % 2 == 1
  s_frm_file:
    seq:
      - id: bb_min
        type: s_cpj_vector
      - id: bb_max
        type: s_cpj_vector
      - id: num_frames
        type: u4
      - id: ofs_frames
        type: u4
      - id: chunk
        type: s_frm_data_chunk
        size-eos: true
    types:
      s_frm_byte_pos:
        seq:
          - id: group
            type: u1
            doc: Compression group number
          - id: pos
            type: u1
            doc: Byte position
            repeat: expr
            repeat-expr: 3
      s_frm_group:
        seq:
          - id: byte_scale
            type: s_cpj_vector
            doc: Scale byte positions by this.
          - id: byte_translate
            type: s_cpj_vector
            doc: Add to position after scale.
      s_frm_data_chunk:
        instances:
          frames:
            pos: _parent.as<s_frm_file>.ofs_frames
            type: s_frm_frame
            repeat: expr
            repeat-expr: _parent.as<s_frm_file>.num_frames
      s_frm_frame:
        seq:
          - id: ofs_frame_name
            type: u4
          - id: bb_min
            type: s_cpj_vector
          - id: bb_max
            type: s_cpj_vector
          - id: num_groups
            type: u4
          - id: ofs_groups
            type: u4
          - id: num_verts
            type: u4
          - id: ofs_verts
            type: u4
        instances:
          frame_name:
            pos: ofs_frame_name
            type: strz
            encoding: ASCII
          frame_groups:
            pos: ofs_groups
            type: s_frm_group
            repeat: expr
            repeat-expr: num_groups
          uncompressed_verticies:
            pos: ofs_verts
            type: s_cpj_vector
            repeat: expr
            repeat-expr: num_verts
            if: num_groups == 0
          compressed_verticies:
            pos: ofs_verts
            type: s_frm_byte_pos
            repeat: expr
            repeat-expr: num_verts
            if: num_groups != 0
    instances:
      name:
        pos: _parent.as<s_cpj_chunk_header>.offset_name - 20
        type: strz
        encoding: ASCII
  s_seq_file:
    seq:
      - id: play_rate
        type: f4
      - id: num_frames
        type: u4
      - id: ofs_frames
        type: u4
      - id: num_events
        type: u4
      - id: ofs_events
        type: u4
      - id: num_bone_info
        type: u4
      - id: ofs_bone_info
        type: u4
      - id: num_bone_translate
        type: u4
      - id: ofs_bone_translate
        type: u4
      - id: num_bone_rotate
        type: u4
      - id: ofs_bone_rotate
        type: u4
      - id: num_bone_scale
        type: u4
      - id: ofs_bone_scale
        type: u4
      - id: chunk
        type: s_seq_data_block
        size-eos: true
    instances:
      name:
        pos: _parent.as<s_cpj_chunk_header>.offset_name - 20
        type: strz
        encoding: ASCII
    types:
      s_seq_bone_scale:
        seq:
          - id: bone_index
            type: u2
            doc: Bone info index.
          - id: reserved
            contents: [0, 0]
            doc: Must be zero.
          - id: scale
            type: s_cpj_vector
            doc: Component scaling values
      s_seq_bone_rotate:
        seq:
          - id: bone_index
            type: u2
            doc: Bone info index.
          - id: roll
            type: s2
            doc: Pitch about Z axis in 64k degrees. Applied first.
          - id: pitch
            type: s2
            doc: Pitch about X axis in 64K degrees. Applied second.
          - id: yaw
            type: s2
            doc: Pitch about Y axis in 64k degrees. Applied last.
      s_seq_bone_translate:
        seq:
          - id: bone_index
            type: u2
            doc: Bone info index
          - id: reserved
            contents: [0, 0]
            doc: MUST be zero.
          - id: translate
            type: s_cpj_vector
            doc: Translation vector
      s_seq_bone_info:
        seq:
          - id: ofs_name
            type: u4
          - id: src_length
            type: f4
            doc: Source skeleton bone length.
        instances:
          name:
            pos: ofs_name
            type: strz
            encoding: ASCII
      s_seq_event:
        seq:
          - id: event_type
            type: u4
          - id: time
            type: f4
            doc: From - to 1
          - id: ofs_param
            type: u4
            doc: FourCC codes
            enum: params
        enums:
          params:
            1297238866: marker
            1414678855: trigger
            1094929732: actor_command
            1413893191: triangle_flags
      s_seq_frame:
        seq:
          - id: reserved
            contents: [0]
          - id: num_bone_translate
            type: u1
          - id: num_bone_rotate
            type: u1
          - id: num_bone_scale
            type: u1
          - id: first_bone_translate
            type: u4
          - id: first_bone_rotate
            type: u4
          - id: first_bone_scale
            type: u4
          - id: ofs_vert_frame_name
            type: u4
        instances:
          vert_frame_name:
            pos: ofs_vert_frame_name
            type: strz
            encoding: ASCII
            if: ofs_vert_frame_name != 0xFFFFFFFF
      s_seq_data_block:
        instances:
          frames:
            pos: _parent.as<s_seq_file>.ofs_frames
            type: s_seq_frame
            repeat: expr
            repeat-expr: _parent.as<s_seq_file>.num_frames
          events:
            pos: _parent.as<s_seq_file>.ofs_events
            type: s_seq_event
            repeat: expr
            repeat-expr: _parent.as<s_seq_file>.num_events
          bone_info:
            pos: _parent.as<s_seq_file>.ofs_bone_info
            type: s_seq_bone_info
            repeat: expr
            repeat-expr: _parent.as<s_seq_file>.num_bone_info
          bone_translations:
            pos: _parent.as<s_seq_file>.ofs_bone_translate
            type: s_seq_bone_translate
            repeat: expr
            repeat-expr: _parent.as<s_seq_file>.num_bone_translate
          bone_rotations:
            pos: _parent.as<s_seq_file>.ofs_bone_rotate
            type: s_seq_bone_rotate
            repeat: expr
            repeat-expr: _parent.as<s_seq_file>.num_bone_rotate
          bone_scales:
            pos: _parent.as<s_seq_file>.ofs_bone_scale
            type: s_seq_bone_scale
            repeat: expr
            repeat-expr: _parent.as<s_seq_file>.num_bone_scale
  s_skl_file:
    seq:
      - id: num_bones
        type: u4
      - id: ofs_bones
        type: u4
      - id: num_verts
        type: u4
      - id: ofs_verts
        type: u4
      - id: num_weights
        type: u4
      - id: ofs_weights
        type: u4
      - id: num_mounts
        type: u4
      - id: ofs_mounts
        type: u4
      - id: chunk
        type: s_skl_data_chunk
        size-eos: true
    instances:
      name:
        pos: _parent.as<s_cpj_chunk_header>.offset_name - 20
        type: strz
        encoding: ASCII
    types:
      s_skl_weight:
        seq:
          - id: bone_index
            type: u4
          - id: weight_factor
            type: f4
          - id: offset_pos
            type: s_cpj_vector
      s_skl_mount:
        seq:
          - id: ofs_name
            type: u4
          - id: bone_index
            type: u4
            doc: -1 if origin
          - id: base_scale
            type: s_cpj_vector
          - id: base_rotate
            type: s_cpj_quat
          - id: base_translate
            type: s_cpj_vector
        instances:
          name:
            pos: ofs_name
            type: strz
            encoding: ASCII
      s_skl_vert:
        seq:
          - id: num_weights
            type: u2
          - id: first_weight
            type: u2
      s_skl_bone:
        seq:
          - id: ofs_name
            type: u4
          - id: parent_index
            type: u4
          - id: base_scale
            type: s_cpj_vector
          - id: base_rotate
            type: s_cpj_quat
          - id: base_translate
            type: s_cpj_vector
          - id: length
            type: f4
        instances:
          name:
            pos: ofs_name
            type: strz
            encoding: ASCII
      s_skl_data_chunk:
        instances:
          bones:
            pos: _parent.as<s_skl_file>.ofs_bones
            type: s_skl_bone
            repeat: expr
            repeat-expr: _parent.as<s_skl_file>.num_bones
          verts:
            pos: _parent.as<s_skl_file>.ofs_verts
            type: s_skl_vert
            repeat: expr
            repeat-expr: _parent.as<s_skl_file>.num_verts
          weights:
            pos: _parent.as<s_skl_file>.ofs_weights
            type: s_skl_weight
            repeat: expr
            repeat-expr: _parent.as<s_skl_file>.num_weights
          mounts:
            pos: _parent.as<s_skl_file>.ofs_mounts
            type: s_skl_mount
            repeat: expr
            repeat-expr: _parent.as<s_skl_file>.num_mounts
  s_mac_file:
    seq: 
      - id: num_sections
        type: u4
      - id: ofs_sections
        type: u4
      - id: num_commands
        type: u4
      - id: ofs_commands
        type: u4
      - id: chunk
        type: s_mac_data_block
        size-eos: true
    instances:
      name:
        pos: _parent.as<s_cpj_chunk_header>.offset_name - 20
        type: strz
        encoding: ascii
    types:
      s_mac_data_block:
        instances:
          sections:
            pos: _parent.as<s_mac_file>.ofs_sections
            type: s_mac_section
            repeat: expr
            repeat-expr: _parent.as<s_mac_file>.num_sections
          commands:
            pos: _parent.as<s_mac_file>.ofs_commands
            type: s_mac_command
            repeat: expr
            repeat-expr: _parent.as<s_mac_file>.num_commands
      s_mac_command:
        seq:
          - id: offset
            type: u4
        instances:
          value:
            pos: offset
            type: strz
            encoding: ASCII
      s_mac_section:
        seq:
          - id: ofs_name
            type: u4
          - id: num_commands
            type: u4
          - id: first_command
            type: u4
        instances:
          name:
            pos: ofs_name
            type: strz
            encoding: ASCII
  s_cpj_vector:
    seq:
      - id: x
        type: f4
      - id: y
        type: f4
      - id: z
        type: f4
  s_cpj_quat:
    seq:
      - id: v
        type: s_cpj_vector
        doc: The vector component
      - id: s
        type: f4
        doc: The scalar component
  s_geo_file:
    seq:
      - id: num_vertices
        type: u4
      - id: ofs_vertices
        type: u4
      - id: num_edges
        type: u4
      - id: ofs_edges
        type: u4
      - id: num_tris
        type: u4
      - id: ofs_tris
        type: u4
      - id: num_mounts
        type: u4
      - id: ofs_mounts
        type: u4
      - id: num_obj_links
        type: u4
      - id: ofs_obj_links
        type: u4
      - id: chunk
        type: s_geo_data_block
        size-eos: true
    instances:
      name:
        pos: _parent.as<s_cpj_chunk_header>.offset_name - 20
        type: strz
        encoding: ASCII
    types:
      s_geo_mount:
        seq:
          - id: ofs_name
            type: u4
          - id: tri_index
            type: u4
          - id: tri_barys
            type: s_cpj_vector
          - id: base_scale
            type: s_cpj_vector
          - id: base_rotate
            type: s_cpj_quat
          - id: base_translate
            type: s_cpj_vector
        instances:
          name:
            pos: ofs_name
            type: strz
            encoding: ascii
      s_geo_tri:
        seq:
          - id: edge_ring
            type: u2
            repeat: expr
            repeat-expr: 3
          - id: reserved
            contents: [0, 0]
            doc: Reserved for future use. MUST be zero.
      s_geo_edge:
        seq:
          - id: head_vertex
            type: u2
          - id: tail_vertex
            type: u2
          - id: inverted_edge
            type: u2
          - id: num_tri_links
            type: u2
          - id: first_tri_link
            type: u4
      s_geo_vert:
        seq:
          - id: flags
            type: u1
            enum: s_geo_vert_flags
          - id: group_index
            type: u1
          - id: reserved
            contents: [0, 0]
            doc: Reserved for future use. MUST be zero.
          - id: num_edge_links
            type: u2
          - id: num_tri_links
            type: u2
          - id: first_edge_link
            type: u4
          - id: first_tri_link
            type: u4
          - id: ref_position
            type: s_cpj_vector
        enums:
          s_geo_vert_flags:
            0x00000000: lod_unlock
            0x00000001: lod_lock
      s_geo_data_block:
        instances:
          vertices:
            pos: _parent.as<s_geo_file>.ofs_vertices
            type: s_geo_vert
            repeat: expr
            repeat-expr: _parent.as<s_geo_file>.num_vertices
          edges:
            pos: _parent.as<s_geo_file>.ofs_edges
            type: s_geo_edge
            repeat: expr
            repeat-expr: _parent.as<s_geo_file>.num_edges
          tris:
            pos: _parent.as<s_geo_file>.ofs_tris
            type: s_geo_tri
            repeat: expr
            repeat-expr: _parent.as<s_geo_file>.num_tris
          mounts:
            pos: _parent.as<s_geo_file>.ofs_mounts
            type: s_geo_mount
            repeat: expr
            repeat-expr: _parent.as<s_geo_file>.num_mounts
          links:
            pos: _parent.as<s_geo_file>.ofs_obj_links
            type: u2
            repeat: expr
            repeat-expr: _parent.as<s_geo_file>.num_obj_links
  s_srf_file:
    seq:
      - id: num_textures
        type: u4
      - id: ofs_textures
        type: u4
      - id: num_tris
        type: u4
      - id: ofs_tris
        type: u4
      - id: num_uv
        type: u4
      - id: ofs_uv
        type: u4
      - id: data_block
        type: s_srf_data_block
        size-eos: true
    instances:
      name:
        pos: _parent.as<s_cpj_chunk_header>.offset_name - 20
        type: strz
        encoding: ASCII
    types:
      s_srf_uv:
        seq:
          - id: u
            type: f4
          - id: v
            type: f4
      s_srf_tri:
        seq:
          - id: uv_index
            type: u2
            repeat: expr
            repeat-expr: 3
          - id: tex_index
            type: u1
          - id: reserved
            contents: [0]
            doc: Reserved for future use. MUST be zero.
          - id: flags
            type: srftf_flags
            size: 4
          - id: smooth_group
            type: u1
          - id: alpha_level
            type: u1
          - id: glaze_tex_index
            type: u1
          - id: glaze_func
            type: u1
            enum: e_srf_glaze
        enums:
          e_srf_glaze:
            0: none
            1: specular
        types:
          srftf_flags:
            seq:
              - id: is_active
                type: b1
              - id: is_hidden
                type: b1
              - id: is_vni_ignored
                type: b1
              - id: is_transparent
                type: b1
              - id: is_unlit
                type: b1
              - id: is_two_sided
                type: b1
              - id: is_masking
                type: b1
              - id: is_modulated
                type: b1
              - id: is_env_mapped
                type: b1
              - id: is_non_collide
                type: b1
              - id: is_tex_blend
                type: b1
              - id: is_z_later
                type: b1
              - id: is_reserved
                type: b1
              
      s_srf_tex:
        seq:
          - id: ofs_name
            type: u4
          - id: ofs_ref_name
            type: u4
        instances:
          name:
            pos: ofs_name
            type: strz
            encoding: ASCII
          ref_name:
            pos: ofs_ref_name
            type: strz
            encoding: ASCII
            if: ofs_name != 0
      s_srf_data_block:
        instances: 
          textures:
            pos: _parent.as<s_srf_file>.ofs_textures
            type: s_srf_tex
            repeat: expr
            repeat-expr: _parent.as<s_srf_file>.num_textures
          triangles:
            pos: _parent.as<s_srf_file>.ofs_tris
            type: s_srf_tri
            repeat: expr
            repeat-expr: _parent.as<s_srf_file>.num_tris
          uvs:
            pos: _parent.as<s_srf_file>.ofs_uv
            type: s_srf_uv
            repeat: expr
            repeat-expr: _parent.as<s_srf_file>.num_uv
  s_lod_file:
    seq:
      - id: num_levels
        type: u4
      - id: ofs_levels
        type: u4
      - id: num_triangles
        type: u4
      - id: ofs_triangles
        type: u4
      - id: num_vert_relay
        type: u4
      - id: offset_vert_relay
        type: u4
      - id: data_block
        type: s_lod_data_block
        size-eos: true
    instances:
      name:
        pos: _parent.as<s_cpj_chunk_header>.offset_name -20
        type: strz
        encoding: ASCII
    types:
      s_lod_tri:
        seq:
          - id: srf_tri_index
            type: u4
          - id: vert_index
            type: s_lod_vert_index
          - id: uv_index
            type: s_lod_uv_index
      s_lod_vert_index:
        seq:
          - id: index
            size: 2
            repeat: expr
            repeat-expr: 3
      s_lod_uv_index:
        seq:
          - id: index
            size: 2
            repeat: expr
            repeat-expr: 3
      s_lod_level:
        seq:
          - id: detail
            type: f4
          - id: num_triangles
            type: u4
          - id: num_vert_relay
            type: u4
          - id: first_triangle
            type: u4
          - id: first_vert_relay
            type: u4
      s_lod_data_block:
        instances:
          triangles:
            pos: _parent.as<s_lod_file>.ofs_triangles
            type: s_lod_tri
            repeat: expr
            repeat-expr: _parent.as<s_lod_file>.num_triangles
          vertex_relays:
            pos: _parent.as<s_lod_file>.offset_vert_relay
            type: u2
            repeat: expr
            repeat-expr: _parent.as<s_lod_file>.num_vert_relay
          levels:
            pos: _parent.as<s_lod_file>.ofs_levels
            type: s_lod_level
            repeat: expr
            repeat-expr: _parent.as<s_lod_file>.num_levels
