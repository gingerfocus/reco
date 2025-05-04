const std = @import("std");

// const fx: type = std.meta.Int(.unsigned, @typeInfo(isize).Int.bits + 8);
pub const fx: type = FixedPoint(10);

// rationals in base 2 are different then base 10, importantly 0.1 is not
// rational in base 2 which is why 0.1+0.2=0.30000000004

// Fixed point value in base 10
pub fn FixedPoint(
    // comptime signedness: std.builtin.Signedness,
    comptime BASE: u16,
) type {
    return packed struct {
        const Self = @This();

        const BASESTR = std.fmt.comptimePrint("{d}", .{BASE});

        const POWERSIZE = 8;
        const DIGETSIZE = 64;

        power: i8 = 0,
        diget: isize = 0,

        // pub fn compinit(comptime value: anytype) Self {
        //     _ = value; // autofix
        // }

        pub fn fromfloat(v: f32) Self {
            const MU = 0.001;

            var power: i8 = 0;

            var nv = v;
            while (nv - @as(f32, @floatFromInt(@as(isize, @intFromFloat(nv)))) > MU) {
                // std.debug.print("estimate: {}, target: {d}, power: {}\n", .{ , nv, power });
                nv = std.math.mul(nv, BASE) catch @panic("overflow");
                power += 1;
            }

            return Self{ .power = power, .diget = @intFromFloat(nv) };
        }

        pub fn add(_x: Self, _y: Self) Self {
            var x = _x;
            var y = _y;
            const power = @max(x.power, y.power);
            x.setpower(power);
            y.setpower(power);
            return Self{
                .power = power,
                .diget = x.diget + y.diget,
            };
        }

        pub fn mul(_x: Self, _y: Self) Self {
            var x = _x;
            var y = _y;
            // const power = @max(x.power, y.power);
            // x.setpower(power);
            // y.setpower(power);

            var res = @mulWithOverflow(x.diget, y.diget);
            while (res[1] != 0 and x.power + x.power < 64) {
                if (x.power > y.power) x.round() else y.round();
                res = @mulWithOverflow(x.diget, y.diget);
            }

            return Self{
                .power = x.power + y.power,
                .diget = res[0],
            };
        }

        pub fn format(
            self: Self,
            comptime _: []const u8,
            opts: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = opts;
            const fmt = "\\frac{{{d}}}{{" ++ BASESTR ++ "^{d}}}";
            try std.fmt.format(writer, fmt, .{ self.diget, self.power });
        }

        pub fn reduce(value: *Self) void {
            while (value.diget & 1 == 0 and value.power > 0) {
                value.diget >>= 1;
                value.power -= 1;
            }
        }

        /// gets the value as an int, discards decimal value
        pub fn asint(x: Self) i64 {
            return x.diget >> x.power;
        }

        pub fn asfloat(x: Self) f32 {
            return @as(f32, @floatFromInt(x.diget)) / @as(f32, @floatFromInt(std.math.pow(i64, BASE, x.power)));
        }

        // pub
        fn setpower(x: *Self, pow: i8) void {
            if (pow <= x.power) return;
            const p = pow - x.power;
            const d = x.diget * std.math.pow(i64, BASE, p);
            x.diget = d;
        }

        fn round(v: *Self) void {
            if (v.power > 0) {
                v.power -= 1;
                v.diget = @divTrunc(v.diget, BASE);
            }
        }
    };
}

fn Base(B1: u16, B2: u16) u16 {
    // TODO: find common primes and see if it can be simplified
    return B1 * B2;
}
fn cross(B1: u16, B2: u16, f1: FixedPoint(B1), f2: FixedPoint(B2)) FixedPoint(Base(B1, B2)) {
    _ = f1; // autofix
    _ = f2; // autofix
    return .{
        .power = 0,
        .diget = 0,
    };
}

comptime {
    std.debug.assert(@sizeOf(fx) == @sizeOf(i72));
}

test "add" {
    const x = FixedPoint.fromFloat(2.25);
    try std.testing.expectEqual(2.25, x.float());

    //const y = FixedPoint.fromFloat(1.3);
}
