const reco = @import("reco");
const std = @import("std");

pub fn main() !void {
    var vall = reco.Variable(usize){ ._value = 3 };
    var addd = reco.Computed(addOne).spawn(.{&vall});
    var mull = reco.call(mulTwo, .{ &vall, &addd.inner });

    std.debug.print("{} + 1 == {}\n", .{ vall.value(), addd.value() });
    std.debug.print("{} * {} == {}\n", .{ vall.value(), addd.value(), mull.value() });

    vall.setvalue(6);
    std.debug.print("{} + 1 == {}\n", .{ vall.value(), addd.value() });
    std.debug.print("{} * {} == {}\n", .{ vall.value(), addd.value(), mull.value() });

    vall.setvalue(42);
    std.debug.print("{} + 1 == {}\n", .{ vall.value(), addd.value() });
    std.debug.print("{} * {} == {}\n", .{ vall.value(), addd.value(), mull.value() });

    // you can also allocate on the heap for larger workloads
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const a = gpa.allocator();
    reco.arena.alloc(a);
    defer reco.arena.deinit();

    var avgg = reco.call(avgThree, .{ &vall, &addd.inner, &mull.inner });

    std.debug.print("{} + 1 == {}\n", .{ vall.value(), addd.value() });
    std.debug.print("{} * {} == {}\n", .{ vall.value(), addd.value(), mull.value() });
    std.debug.print("avg({}, {}, {}) == {}\n", .{ vall.value(), addd.value(), mull.value(), avgg.value() });

    vall.setvalue(11);
    std.debug.print("{} + 1 == {}\n", .{ vall.value(), addd.value() });
    std.debug.print("{} * {} == {}\n", .{ vall.value(), addd.value(), mull.value() });
    std.debug.print("avg({}, {}, {}) == {}\n", .{ vall.value(), addd.value(), mull.value(), avgg.value() });

    var name = reco.vari(@as([]const u8, "evan"));
    var hello = reco.Computed(greet).spawn(.{&name});
    name.setvalue("joel");
    name.setvalue("billy");
    // TODO: having to call this value function on voids is annoying
    // but I dont see a better way
    hello.value();
}

fn addOne(in: usize) usize {
    return in + 1;
}

fn mulTwo(x: usize, y: usize) usize {
    return x * y;
}

fn avgThree(x: usize, y: usize, z: usize) u32 {
    return @truncate((x + y + z) / 3);
}

fn greet(name: []const u8) void {
    std.debug.print("hello, {s}!\n", .{name});
}
