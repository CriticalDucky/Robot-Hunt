local ServerStorage = game:GetService("ServerStorage")

local serverStorageVendor = ServerStorage.Vendor

local ReplicaService = require(serverStorageVendor.ReplicaService)

local timeReplica = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("ServerUnixTime"),
    Data = {
        timeInfo = {
            unix = os.time()
        }
    },
    Replication = "All"
})

while task.wait(180) do
    timeReplica:SetValue({"timeInfo", "unix"}, os.time())
end