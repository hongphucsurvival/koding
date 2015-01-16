package main

import (
	"koding/db/mongodb/modelhelper"
	"time"
)

// request arguments
type requestArgs struct {
	MachineId string `json:"machineId"`
	Reason    string `json:"reason"`
}

func stopVm(machineId, username, reason string) error {
	if controller.Klient == nil {
		Log.Debug("Klient not initialized. Not stopping: %s", machineId)
		return nil
	}

	_, err := controller.Klient.Tell("stop", &requestArgs{
		MachineId: machineId, Reason: reason,
	})

	return err
}

var BlockDuration = time.Hour * 24 * 365

func blockUserAndDestroyVm(machineId, username, reason string) error {
	machines, err := modelhelper.GetMachinesForUsername(username)
	if err != nil {
		return err
	}

	if controller.Klient != nil {
		for _, machine := range machines {
			_, err := controller.Klient.Tell("destroy", &requestArgs{
				MachineId: machine.ObjectId.Hex()},
			)

			if err != nil {
				Log.Error(err.Error())
			}
		}
	}

	return modelhelper.BlockUser(username, reason, BlockDuration)
}
