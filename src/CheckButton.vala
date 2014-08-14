/*
 * ev3dev-tk - graphical toolkit for LEGO MINDSTORMS EV3
 *
 * Copyright 2014 David Lechner <david@lechnology.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 */

/* CheckButton.vala - Widget that represents a checkbox or radio button */

using Curses;
using Gee;
using GRX;

namespace EV3devTk {

    public enum CheckButtonType {
        CHECKBOX,
        RADIO;
    }

    public class CheckButtonGroup : Object {
        public CheckButton selected_item { get; internal set; }
        public CheckButtonGroup () {
        }
    }

    public class CheckButton : EV3devTk.Widget {
        CheckButtonType check_button_type;

        bool _checked = false;
        public bool checked {
            get { return _checked; }
            set {
                _checked = value;
                if (checked && group != null) {
                    group.selected_item = this;
                    if (window != null) {
                        /* uncheck all other CheckButtons with the same group name */
                        window.do_recursive_children ((widget) => {
                            var check_button = widget as CheckButton;
                            if (check_button != null && check_button != this
                                && check_button.group == group)
                                check_button.checked = false;
                            return null;
                        });
                    }
                }
                if (!checked && group != null && group.selected_item == this)
                    group.selected_item = null;
            }
        }
        public CheckButtonGroup? group { get; private set; }

        public int outer_size { get; set; default = 9; }
        public int inner_size { get; set; default = 5; }

        CheckButton (CheckButtonType type, CheckButtonGroup? group = null)
        {
            check_button_type = type;
            this.group = group;
            padding_top = 2;
            padding_bottom = 2;
            padding_left = 2;
            padding_right = 2;
            can_focus = true;

            notify["checked"].connect (redraw);
            notify["outer_size"].connect (redraw);
            notify["inner_size"].connect (redraw);
        }

        public CheckButton.checkbox () {
            this (CheckButtonType.CHECKBOX);
        }

        public CheckButton.radio (CheckButtonGroup group) {
            this (CheckButtonType.RADIO, group);
        }

        public override int get_preferred_width () {
            return outer_size + get_margin_border_padding_width ();
        }

        public override int get_preferred_height () {
            return outer_size + get_margin_border_padding_height ();
        }

        protected override void on_draw (Context context) {
            weak Widget widget = this;
            while (widget.parent != null) {
                if (widget.can_focus)
                    break;
                else
                    widget = widget.parent;
            }
            unowned GRX.Color color;
            if (widget.has_focus) {
                color = window.screen.mid_color;
                filled_box (border_bounds.x1, border_bounds.y1, border_bounds.x2,
                    border_bounds.y2, color);
                color = window.screen.bg_color;
            } else
                color = window.screen.fg_color;
            if (check_button_type == CheckButtonType.CHECKBOX)
                box (content_bounds.x1, content_bounds.y1, content_bounds.x2,
                    content_bounds.y2, color);
            else
                circle (content_bounds.x1 + outer_size / 2,
                    content_bounds.y1 + outer_size / 2, outer_size / 2, color);
            if (checked) {
                if (check_button_type == CheckButtonType.CHECKBOX) {
                    var x = content_bounds.x1 + (outer_size - inner_size) / 2;
                    var y = content_bounds.y1 + (outer_size - inner_size) / 2;
                    filled_box (x, y, x + inner_size - 1, y + inner_size - 1, color);
                } else
                    filled_circle (content_bounds.x1 + outer_size / 2,
                        content_bounds.y1 + outer_size / 2, inner_size / 2, color);
            }
        }

        protected override bool on_key_pressed (uint key_code) {
            if (key_code == '\n') {
                if (check_button_type == CheckButtonType.CHECKBOX)
                    checked = !checked;
                else
                    checked = true;
                Signal.stop_emission_by_name (this, "key-pressed");
                return true;
            }
            return base.on_key_pressed (key_code);
        }
    }
}
