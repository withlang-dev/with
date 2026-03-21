use demo.core

type Pair = {
    device: Device,
}

pub fn ok(device: Device) -> bool:
    let pair = Pair { device }
    pair.device == device
