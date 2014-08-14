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

/* Widget.vala - Base class for all widgets */

using Curses;
using GRX;

namespace EV3devTk {
    public delegate Widget? WidgetFunc (Widget widget);

    public enum FocusDirection {
        UP,
        DOWN,
        LEFT,
        RIGHT;
    }

    public abstract class Widget : Object {
        /* layout properties */

        /* bounding rectangles - set by parent container */
        protected Rectangle bounds;
        protected Rectangle border_bounds;
        protected Rectangle content_bounds;

        public virtual int margin_top { get; set; default = 0; }
        public virtual int margin_bottom { get; set; default = 0; }
        public virtual int margin_left { get; set; default = 0; }
        public virtual int margin_right { get; set; default = 0; }

        internal virtual int border_top { get; protected set; default = 0; }
        internal virtual int border_bottom { get; protected set; default = 0; }
        internal virtual int border_left { get; protected set; default = 0; }
        internal virtual int border_right { get; protected set; default = 0; }

        public virtual int padding_top { get; set; default = 0; }
        public virtual int padding_bottom { get; set; default = 0; }
        public virtual int padding_left { get; set; default = 0; }
        public virtual int padding_right { get; set; default = 0; }

        public WidgetAlign horizontal_align {
            get; set; default = WidgetAlign.FILL;
        }
        public WidgetAlign vertical_align {
            get; set; default = WidgetAlign.FILL;
        }

        /* navigation properties */

        /**
         * This widget can take the focus
         */
        public bool can_focus { get; set; }
        /**
         * This widget has focus
         */
        public bool has_focus { get; protected set; default = false; }

        public Container? parent { get; protected set; }

        public Window? window {
            owned get {
                return do_recursive_parent ((widget) => {
                    return widget as Window;
                }) as Window;
            }
        }

        public void *represented_object_pointer { get; set; }
        public Object? represented_object {
            get { return (Object)represented_object_pointer; }
            set {
                if (value != null)
                    value.ref ();
                if (represented_object != null)
                    represented_object.unref ();
                represented_object_pointer = value;
            }
        }

        protected Widget () {
            draw.connect (on_draw);
            key_pressed.connect (on_key_pressed);
            notify["margin_top"].connect (redraw);
            notify["margin_bottom"].connect (redraw);
            notify["margin_left"].connect (redraw);
            notify["margin_right"].connect (redraw);
            notify["border_top"].connect (redraw);
            notify["border_bottom"].connect (redraw);
            notify["border_left"].connect (redraw);
            notify["border_right"].connect (redraw);
            notify["padding_top"].connect (redraw);
            notify["padding_bottom"].connect (redraw);
            notify["padding_left"].connect (redraw);
            notify["padding_right"].connect (redraw);
            notify["horizontal_align"].connect (redraw);
            notify["vertical_align"].connect (redraw);
            notify["can_focus"].connect (redraw);
            notify["has_focus"].connect (redraw);

            notify["can_focus"].connect (() => has_focus = false);
        }

        /* layout functions */

        public int get_margin_border_padding_width () {
            return margin_left + margin_right + border_left
                + border_right + padding_left + padding_right;
        }

        public int get_margin_border_padding_height () {
            return margin_top + margin_bottom + border_top
                + border_bottom + padding_top + padding_bottom;
        }

        public virtual int get_preferred_width () {
            return get_margin_border_padding_width ();
        }
        public virtual int get_preferred_height () {
            return get_margin_border_padding_height ();
        }

        public virtual int get_preferred_width_for_height (int height) {
            return get_preferred_width ();
        }

        public virtual int get_preferred_height_for_width (int width) {
            return get_preferred_height ();
        }

        public void set_bounds (int x1, int y1, int x2, int y2) {
            bounds.x1 = x1;
            bounds.y1 = y1;
            bounds.x2 = x2;
            bounds.y2 = y2;
            border_bounds.x1 = x1 + margin_left;
            border_bounds.y1 = y1 + margin_top;
            border_bounds.x2 = x2 - margin_right;
            border_bounds.y2 = y2 - margin_bottom;
            content_bounds.x1 = x1 + margin_left + border_left + padding_left;
            content_bounds.y1 = y1 + margin_top + border_top + padding_top;
            content_bounds.x2 = x2 - margin_right - border_right - padding_right;
            content_bounds.y2 = y2 - margin_bottom - border_bottom - padding_bottom;
        }

        /* navigation functions */

        public bool focus () {
            if (!can_focus)
                return false;
            if (window != null) {
                window.do_recursive_children ((widget) => {
                    widget.has_focus = false;
                    return null;
                });
            }
            has_focus = true;
            redraw ();
            return true;
        }

        public virtual bool focus_next (FocusDirection direction) {
            return false;
        }

        /* tree traversal functions */

        /**
         * Run a function recursively over widget and all of its children
         * (if any). The recursion stops when func returns a non-null
         * value. That value is returned by do_recursive_children.
         */
        public Widget? do_recursive_children (WidgetFunc func, bool reverse = false) {
            return do_recursive_children_internal (this, func, reverse);
        }

        public static Widget? do_recursive_children_internal (
            Widget widget, WidgetFunc func, bool reverse)
        {
            var result = func (widget);
            if (result != null)
                return result;
            var container = widget as Container;
            if (container != null && container.children.size > 0) {
                var iter = container.children.list_iterator ();
                if (reverse) {
                    iter.last ();
                    do {
                        result = do_recursive_children_internal (iter.get (), func, reverse);
                        if (result != null)
                            return result;
                    } while (iter.previous ());
                } else {
                    iter.first ();
                    do {
                        result = do_recursive_children_internal (iter.get (), func, reverse);
                        if (result != null)
                            return result;
                    } while (iter.next ());
                }
            }
            return null;
        }

        /**
         * Run a function recursively over widget and all of its ancestors
         * (if any). The recursion stops when func returns a non-null
         * value. That value is returned by do_recursive_parent.
         */
        public Widget? do_recursive_parent (WidgetFunc func) {
            return do_recursive_parent_internal (this, func);
        }

        public static Widget? do_recursive_parent_internal (
            Widget widget, WidgetFunc func)
        {
            var result = func (widget);
            if (result != null)
                return result;
            if (widget.parent != null)
                return do_recursive_parent_internal (widget.parent, func);
            return null;
        }

        /* drawing functions */

        public signal void draw (Context context);
        public virtual void redraw () {
            if (parent != null)
                parent.redraw ();
        }
        protected abstract void on_draw (Context context);

        /* input handling */

        public signal bool key_pressed (uint key_code);
        protected virtual bool on_key_pressed (uint key_code) {
            if (can_focus) {
                FocusDirection direction;
                switch (key_code) {
                case Key.UP:
                    direction = FocusDirection.UP;
                    break;
                case Key.DOWN:
                    direction = FocusDirection.DOWN;
                    break;
                case Key.LEFT:
                    direction = FocusDirection.LEFT;
                    break;
                case Key.RIGHT:
                    direction = FocusDirection.RIGHT;
                    break;
                default:
                    return false;
                }
                do_recursive_parent ((widget) => {
                    if (widget.focus_next (direction))
                        return widget;
                    return null;
                });
                Signal.stop_emission_by_name (this, "key-pressed");
                return true;
            }
            return false;
        }
    }
}
