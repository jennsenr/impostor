package vo

import "strings"

type DeviceStatus int

const (
	DeviceStatusUnknown DeviceStatus = iota
	DeviceStatusActivated
	DeviceStatusUpdated

	DeviceStatusUnknownValue = "UNKNOWN"
	DeviceStatusActivatedValue = "ACTIVATED"
	DeviceStatusUpdatedValue = "UPDATED"
)

func NewDeviceStatusFromString(value string) DeviceStatus {
	v := strings.ToUpper(strings.TrimSpace(value))
	switch v {
	case DeviceStatusUnknownValue:
		return DeviceStatusUnknown
	case DeviceStatusActivatedValue:
		return DeviceStatusActivated
	case DeviceStatusUpdatedValue:
		return DeviceStatusUpdated
	default:
		return DeviceStatusUnknown
	}
}

func (e DeviceStatus) Value() string {
	return [...]string{
		DeviceStatusUnknownValue,
		DeviceStatusActivatedValue,
		DeviceStatusUpdatedValue,
	}[e]
}
























