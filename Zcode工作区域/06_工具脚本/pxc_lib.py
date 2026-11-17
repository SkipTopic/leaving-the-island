# -*- coding: utf-8 -*-
"""pxc_lib.py — 程序化构造 Pixel Composer (.pxc) 工程文件。
格式（逆向自 1.21.8 样例）:
  b'PXCX' + u32(主数据偏移) + [b'THMB'+u32+zlib(256*256*4缩略图)] + [b'META'+u32(u32版本号+版本串+NUL)] + zlib(JSON+NUL)
集合 .pxcc = 裸 JSON {versionStr, version, nodes[]}
工程 JSON: 一个大 dict，nodes[] 每节点带 type/name/inputs/inspectInputs/outputs。
连接: 目标节点 inputs[i] 里写 from_node(源节点id)/from_index(源输出口)/from_tag:0。
"""
import copy, json, struct, zlib

VERSION_STR = "1.21.8.008"
VERSION_INT = 121070

# ---- 输入/检视输入样板（逆向自官方样例，字段缺一不可） ----
_ATTRI_IN = {"show_graphs": [], "graph_range": [0, 1], "override_instance": False}
_ATTRI_NODE = {"cache": False, "resizeManual": False, "show_timeline": False,
               "show_parameter": False, "preview_size": 128, "process": True,
               "color_depth": 1, "timeline_hide": False, "timeline_override": False,
               "show_render_frame": False, "show_preview": True}


def inp(value=None, linked_from=None, from_index=0, extra=None):
    """构造一个 input 条目。linked_from=(源节点id, 源输出口) 时为连线。"""
    e = {"curveMode": False, "attri": copy.deepcopy(_ATTRI_IN), "unit": 0,
         "scoll": None, "r": {"d": value}, "def_val": value}
    if linked_from is not None:
        e["from_node"], e["from_index"], e["from_tag"] = linked_from[0], linked_from[1], 0
        e["linked"] = True
    if extra:
        e.update(extra)
    return e


def inspect_input(value=False):
    e = {"curveMode": False, "attri": copy.deepcopy(_ATTRI_IN), "unit": 0,
         "scoll": None, "v": 1, "r": {"d": value}, "def_val": value}
    return e


_NODE_SEQ = [0]


def make_node(node_type, name, x=0, y=0, inputs=None, outputs=None, inspect_values=None,
              extra=None):
    """构造一个节点。inspect_values 依次填 5 个检视输入的值。"""
    _NODE_SEQ[0] += 1
    nid = "gA8Aprog%06dZautoGen" % _NODE_SEQ[0]
    insp = [inspect_input(v) for v in (inspect_values or [False] * 5)]
    while len(insp) < 5:
        insp.append(inspect_input(False))
    node = {"x": x, "y": y,
            "inputs": inputs or [],
            "insp_col": {},
            "attri": copy.deepcopy(_ATTRI_NODE),
            "attriTool": {},
            "inspectInputs": insp,
            "outputs": outputs if outputs is not None else [{}],
            "renamed": True,
            "id": nid,
            "iname": "%s%05d" % (name.replace(" ", ""), _NODE_SEQ[0]),
            "name": name,
            "version": VERSION_INT,
            "type": node_type}
    if extra:
        node.update(extra)
    return node


def read_pxc(path):
    """读 .pxc → (工程dict, 缩略图raw或None)。也兼容裸 JSON 的 .pxcc。"""
    data = open(path, "rb").read()
    if data[:4] == b"PXCX":
        off = struct.unpack("<I", data[4:8])[0]
        txt = zlib.decompress(data[off:]).decode("utf-8").rstrip("\x00")
        return json.loads(txt), None
    return json.loads(data.decode("utf-8")), None


def write_pxc(path, project, thumb_rgba=None):
    """工程 dict → .pxc。thumb_rgba=None 则写全黑缩略图。"""
    thumb = thumb_rgba if thumb_rgba else bytes(256 * 256 * 4)
    txt = json.dumps(project, ensure_ascii=False) + "\x00"
    main = zlib.compress(txt.encode("utf-8"), 6)
    meta = struct.pack("<I", VERSION_INT) + VERSION_STR.encode("ascii") + b"\x00"
    zthumb = zlib.compress(thumb, 6)
    # 布局: PXCX(4)+u32(4) | THMB+u32+z | META+u32+meta | 主zlib
    head = 8 + (4 + 4 + len(zthumb)) + (4 + 4 + len(meta))
    out = bytearray()
    out += b"PXCX" + struct.pack("<I", head)
    out += b"THMB" + struct.pack("<I", len(zthumb)) + zthumb
    out += b"META" + struct.pack("<I", len(meta)) + meta
    out += main
    open(path, "wb").write(bytes(out))
    return path


_SKELETON = json.loads('{"versions": "1.21.8.008", "previewRuler": [], "timelines": {"name": "New folder", "show": true, "color": -1, "timeline_hide": false, "contents": [], "type": "Folder"}, "load_layout": false, "usage_timer": 26.995841999999968, "is_nightly": true, "freeze": false, "graphConnection": {"line_corner": 4, "line_width": 1, "line_highlight_all": false, "connect_on_create": false, "line_highlight": 0, "line_highlight_fade": 0.75, "line_extend": 16, "line_aa": 2, "line_sample": 1, "type": 0}, "version": 121070, "randomizer": {"values": []}, "preview": "", "data": {"hlsl": {}}, "global_node": {"inputs": [], "attri": {"update_graph": true, "show_update_trigger": false, "timeline_hide": false, "color": -1, "timeline_override": false, "show_timeline": false}}, "graphGrid": {"snap": true, "size": 16, "show": true, "show_origin": false, "color": 4294967295, "opacity": 0.05, "highlight": 12}, "metadata": {"contact": "", "deprecated": false, "preview_frames": 1, "aut_id": 0, "file_id": 0, "author": "MakhamDev", "description": "", "isDefault": false, "version": 117100, "tags": [], "alias": ""}, "onion_skin": {"step": 1, "range": [-1, 1], "color": [4278190335, 4294901760], "on_top": true, "enabled": false, "alpha": 0.5}, "previewNode": -4, "inspectingNode": "gA8Apf8412073UssiKN8GZw8JkQHmRlc", "graph_display_parameter": {"show_grid": true, "preview_scale": 100, "avoid_label": false, "node_meta_view": 2, "show_dimension": true, "show_tooltip": true, "show_compute": true, "highlight": 0, "show_view_control": 1, "show_topbar": true}, "composer": -4, "favVal": [], "cPanels": [], "attributes": {"bind_gamemaker_path": "", "color_depth": 1, "interpolate": 0, "oversample": 3, "strict": false, "palette": [4281289406, 4282611415, 4289385706, 4285703908, 4283461560, 4281941619, 4281411390, 4281542306, 4282661860, 4280448759, 4281642750, 4284606462, 4283287395, 4282943806, 4282539046, 4282268697, 4287188498, 4292581632, 4294305836, 4294967295, 4292660160, 4290026379, 4287129946, 4284892218, 4282657574, 4280620056, 4282646783, 4285282408, 4287123637, 4286215670, 4288067560, 4285105602], "palette_fix": false, "slideshow_render_only": false, "auto_organize": false, "export_dir": "", "surface_dimension": [64, 64], "global_layer": false, "shader": 0, "bind_godot_path": "", "env_variables": {"json_asset_dir": "-"}, "render_topo": false, "use_unit_in_connect": true, "autosave": false}, "tMarks": [], "aRegion": [], "nodePosition": {}, "previewGrid": {"pixelScale": 16, "pixelAlway": false, "pixel": false, "size": [16, 16], "d3_color": 16777215, "d3_opacity": 0.75, "d3_scale": 8, "color": 4286672237, "d3_show": true, "snap": false, "show": false, "opacity": 0.5, "pixelColor": 4286672237, "pixelAlpha": 0.5}, "addon": {}, "readonly": false, "notes": [], "trackAnim": {"animated": false, "onode": -1, "tracks": [], "titleColor": 6722047, "intro_duration": 60, "outro_duration": 60, "intro_animation_speed": 1, "outro_animation_speed": 1, "audio_intro": "", "title": "", "audio_loop": "", "audio_outtro": ""}, "animator": {"frame_range_end": null, "frames_total": 30, "framerate": 30, "playback": 0, "frame_range_start": null}}')


def base_project(nodes, surface=(64, 64), frames_total=30, framerate=30,
                 export_dir="", preview_node=-4):
    """以官方样例骨架为底（键/类型全兼容），仅覆写需要的字段。"""
    import copy
    prj = copy.deepcopy(_SKELETON)
    prj["nodes"] = nodes
    prj["attributes"]["surface_dimension"] = list(surface)
    prj["attributes"]["export_dir"] = export_dir
    prj["animator"]["frames_total"] = frames_total
    prj["animator"]["framerate"] = framerate
    prj["previewNode"] = preview_node
    prj["metadata"]["author"] = "ZCode"
    return prj
