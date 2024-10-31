const reco = @import("reco");
const std = @import("std");

pub fn main() !void {
    var x = reco.Variable(usize){ ._value = 3 };
    var y = reco.vari(@as(usize, 1));
    var ad = reco.call(add, .{ x.ref(), y.ref() });
    var addd = reco.Computed(addOne).spawn(.{ad.ref()});
    var mull = reco.call(mulTwo, .{ x.ref(), addd.ref() });

    std.debug.print("{} + 1 == {}\n", .{ x.value(), addd.value() });
    std.debug.print("{} * {} == {}\n", .{ x.value(), addd.value(), mull.value() });

    x.setvalue(6);
    std.debug.print("{} + 1 == {}\n", .{ x.value(), addd.value() });
    std.debug.print("{} * {} == {}\n", .{ x.value(), addd.value(), mull.value() });

    x.setvalue(42);
    std.debug.print("{} + 1 == {}\n", .{ x.value(), addd.value() });
    std.debug.print("{} * {} == {}\n", .{ x.value(), addd.value(), mull.value() });

    // you can also allocate on the heap for larger workloads
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const a = gpa.allocator();
    reco.arena.alloc(a);
    defer reco.arena.deinit();

    var avgg = reco.call(avgThree, .{ &x, &addd.inner, &mull.inner });

    std.debug.print("{} + 1 == {}\n", .{ x.value(), addd.value() });
    std.debug.print("{} * {} == {}\n", .{ x.value(), addd.value(), mull.value() });
    std.debug.print("avg({}, {}, {}) == {}\n", .{ x.value(), addd.value(), mull.value(), avgg.value() });

    x.setvalue(11);
    std.debug.print("{} + 1 == {}\n", .{ x.value(), addd.value() });
    std.debug.print("{} * {} == {}\n", .{ x.value(), addd.value(), mull.value() });
    std.debug.print("avg({}, {}, {}) == {}\n", .{ x.value(), addd.value(), mull.value(), avgg.value() });

    var name = reco.vari(@as([]const u8, "evan"));
    var hello = reco.Computed(greet).spawn(.{&name});
    name.setvalue("joel");
    name.setvalue("billy");
    // TODO: having to call this value function on voids is annoying
    // but I dont see a better way
    hello.value();
}

fn add(x: usize, y: usize) usize {
    return x + y;
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
