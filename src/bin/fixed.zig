const lib = @import("root.zig");
const std = @import("std");

// pub fn main() !void {
//     const xvalue = 2.25;
//     const yvalue = 1.15;
//     const x = lib.FixedPoint.fromfloat(xvalue);
//     const y = lib.FixedPoint.fromfloat(yvalue);
//     std.debug.print("x({d:8}): {d}\n", .{ xvalue, x.asfloat() });
//     std.debug.print("y({d:8}): {d}\n", .{ yvalue, y.asfloat() });
//
//     const z = x.add(y);
//     std.debug.print("z = {} = {d}\n", .{ z, z.asfloat() });
//
//     const a = x.mul(x);
//     std.debug.print("a = {} = {d}\n", .{ a, a.asfloat() });
//
//     const b = a.mul(z);
//     std.debug.print("b = {} = {d}\n", .{ b, b.asfloat() });
//
//     const c = b.mul(b);
//     std.debug.print("c = {} = {d}\n", .{ c, c.asfloat() });
//
//     const d = c.mul(b);
//     std.debug.print("d = {} = {d}\n", .{ d, d.asfloat() });
// }

const T = blk: {
    // break :blk lib.FixedPoint(2);
    break :blk lib.fx;
};

pub fn main() !void {
    const xvalue = 0.25;
    const yvalue = 0.125;
    const x = T.fromfloat(xvalue);
    const y = T.fromfloat(yvalue);
    std.debug.print("x({d:8}): {d}\n", .{ xvalue, x.asfloat() });
    std.debug.print("y({d:8}): {d}\n", .{ yvalue, y.asfloat() });

    var z = x.add(y);
    std.debug.print("z({d:8})= {} = {d}\n", .{ xvalue + yvalue, z, z.asfloat() });

    std.debug.print("z({d:8})= {} = {d}\n", .{ xvalue + yvalue, z, z.asfloat() });
}
