//! A reactive programming library for creating and managing reactive values and computations.

const std = @import("std");

pub const arena = struct {
    const ARENA_SIZE = 4096;
    var _arena: [ARENA_SIZE]bool = .{false} ** ARENA_SIZE;
    var _index: usize = 0;
    var _alloc: ?std.heap.ArenaAllocator = null;

    pub fn next() *bool {
        if (_alloc) |*a| {
            const changed = a.allocator().create(bool) catch @panic("OOM");
            return changed;
        }

        if (_index >= ARENA_SIZE)
            @panic("exceeded max stack allocation, consider adding an allocator with `arena.alloc`");

        const changed = &_arena[_index];
        _index += 1;
        return changed;
    }

    /// Cause new `Variable`s to use heap allocated update flags. Call
    /// `arena.deinit` at the end to cleanup.
    pub fn alloc(a: std.mem.Allocator) void {
        _alloc = std.heap.ArenaAllocator.init(a);
    }

    pub fn deinit() void {
        if (_alloc) |a| a.deinit();
    }
};

pub const Observer = struct {
    changed: *bool,

    pub inline fn update(self: Observer) void {
        self.changed.* = true;
    }
};

/// The base implementation
pub fn Variable(comptime T: type) type {
    // A container that holds a reactive value.
    //
    // Args:
    //     value: The initial value of the signal, which can be a nested structure.
    //
    //     Attributes:
    //         _value (NestedValue[T]): The current value of the signal.
    return struct {
        const Self = @This();
        const OBSERVER_BUFFER_SIZE = 4;

        /// The value
        _value: T,
        /// Things that depend on this value, notify them when changed
        _observers: [OBSERVER_BUFFER_SIZE]Observer = .{undefined} ** OBSERVER_BUFFER_SIZE,
        _obCurSize: usize = 0,

        pub inline fn value(self: Self) T {
            return self._value;
        }

        /// Sets the current value. Observers will be notified if the value has
        /// changed.
        pub fn setvalue(self: *Self, new: T) void {
            // const old = self._value;
            // var change = !std.mem.eql(u8, std.mem.asBytes(&old), std.mem.asBytes(&new));
            // if (@typeInfo(T) == .Fn) change = true;
            const change = true;

            if (change) {
                self._value = new;
                self.update();
            }
        }

        /// Notify all observers by calling their update method.
        pub fn update(self: *Self) void {
            for (self._observers[0..self._obCurSize]) |ob| ob.update();
        }

        /// Subscribe an observer to this variable.
        pub fn subscribe(self: *Self, ob: Observer) void {
            if (self._obCurSize >= OBSERVER_BUFFER_SIZE)
                @panic("maximum function arguments is " ++ std.fmt.comptimePrint("{}", .{OBSERVER_BUFFER_SIZE}));

            // check if already in list
            for (self._observers[0..self._obCurSize]) |item| {
                if (item.changed == ob.changed) return;
            }

            self._observers[self._obCurSize] = ob;
            self._obCurSize += 1;
        }

        // Unsubscribe an observer from this variable.
        pub fn unsubscribe(self: *Self, ob: Observer) void {
            for (self._observers[0..self._obCurSize], 0..) |observer, i| {
                if (observer.changed == ob.changed) {
                    // swap with the last one, potentially the same item
                    self._observers[i] = self._observers[self._obCurSize - 1];
                    // remove the last item (has now been moved to i)
                    self._observers[self._obCurSize - 1] = undefined;
                    // cut it from the list
                    self._obCurSize -= 1;
                    return;
                }
            }
        }
    };
}

fn Emiter(comptime T: type) type {
    return struct {
        dataptr: *anyopaque,
        valuefn: *const fn (*anyopaque) *T,
        subscribefn: *const fn (*anyopaque, Observer) void,
        unsubscribefn: *const fn (*anyopaque, Observer) void,
    };
}

pub fn Computed(comptime function: anytype) type {
    const T: type = @typeInfo(@TypeOf(function)).Fn.return_type orelse @panic("");

    const FnArgs: type = std.meta.ArgsTuple(@TypeOf(function));

    const feilds = @typeInfo(FnArgs).Struct.fields;
    var types: [feilds.len]type = undefined;
    for (feilds, 0..) |feild, i| types[i] = *Variable(feild.type);
    const InputArgs: type = std.meta.Tuple(&types);

    // A reactive value defined by a function.
    return struct {
        const Self = @This();

        inner: Variable(T),
        f: *const fn (FnArgs) T,

        args: InputArgs,

        changed: *bool,

        pub fn spawn(args: InputArgs) Self {
            const thunk = struct {
                fn cast(pargs: FnArgs) T {
                    return @call(.auto, function, pargs);
                }
            };

            var self = Self{
                .f = thunk.cast,
                .inner = .{ ._value = undefined },
                .args = args,
                .changed = arena.next(),
            };
            self.update(); // this value `self.inner._value` defined

            // observe our dependencies
            inline for (args) |arg| {
                comptime var Ty: type = @TypeOf(arg);
                if (@typeInfo(Ty) == .Pointer) {
                    Ty = @typeInfo(Ty).Pointer.child;
                } else continue;

                if (std.meta.hasFn(Ty, "subscribe")) {
                    arg.subscribe(self.observer());
                }
            }
            return self;
        }

        fn update(self: *Self) void {
            var pargs: FnArgs = undefined;
            inline for (self.args, 0..) |arg, i| {
                const Ty = @TypeOf(arg);
                if (@typeInfo(Ty) == .Pointer) {
                    const Temp = @typeInfo(Ty).Pointer.child;
                    if (std.meta.hasFn(Temp, "value")) {
                        pargs[i] = arg.value();
                        continue;
                    }
                }
                pargs[i] = arg;
            }

            const val = self.f(pargs);
            self.inner.setvalue(val);
        }

        pub fn observer(self: Self) Observer {
            return Observer{ .changed = self.changed };
        }

        pub inline fn subscribe(self: *Self, ob: Observer) void {
            self.inner.subscribe(ob);
        }

        pub inline fn unsubscribe(self: *Self, ob: Observer) void {
            self.inner.unsubscribe(ob);
        }

        /// Get the current value.
        pub inline fn value(self: *Self) T {
            if (self.changed.*) {
                self.update();
                self.changed.* = false;
            }
            return self.inner._value;
        }
    };
}

pub fn call(comptime Function: anytype, args: anytype) Computed(Function) {
    return Computed(Function).spawn(args);
}

pub fn vari(value: anytype) Variable(@TypeOf(value)) {
    return Variable(@TypeOf(value)){ ._value = value };
}
