<template>
  <div class="container">
    <div v-if="online">
      <div class="flex">
        <img
          src="../../img/ipfs.png"
          alt="IPFS logo"
          style="width: auto; height: 8em"
        />
        <div style="text-align: right; padding-left: 2em">
          <p v-if="peers">
            Connected to <span class="coldlight">{{ peers.length }} peers</span>
          </p>
          <div>
            <p>
              Pinning
              <span class="coldlight"
                >{{ Object.keys(objkts).length }} Objkts</span
              >
            </p>
            <p>
              Hosting <span class="coldlight">{{ size }}/{{ max }} GB</span>
            </p>
            <progress
              :value="size"
              :max="max"
              :class="progressClass"
            ></progress>
          </div>
        </div>
      </div>
    </div>
    <div class="section" v-else>
      <h2>Hmmmm... I can't seem to connect to your local IPFS node 🤔</h2>
      <hr style="margin: 3em 0" />
      <ol>
        <li>
          Download
          <a
            href="https://docs.ipfs.io/install/ipfs-desktop/#install-instructions"
            >IPFS Desktop</a
          >
          (or the commandline client) for your respective operating system.
        </li>
        <li>
          Make sure your node is running:
          <span class="highlight">menubar/taskbar</span> for the desktop app or
          <code>ipfs daemon</code> on the command-line.
        </li>
        <li>
          <p>
            Add <code>https://pinitforward.xyz</code> to the
            <a
              href="https://github.com/ipfs/ipfs-webui#configure-ipfs-api-cors-headers"
              >cross-origin requests list</a
            >
            and restart your node.
          </p>
          <ul>
            <li>
              Commandline 👉
              <code
                >/bin/bash -c "$(curl -fsSL
                https://pinitforward.xyz/cors-config.sh)"</code
              >
            </li>
            <li>
              Desktop 👇
              <a href="../../img/ipfs-cors.png">
                <img
                  src="../../img/ipfs-cors.png"
                  alt="add https://pinitforward.xyz
            to IPFS config"
                  style="margin: 1em 0; width: 100%"
                />
              </a>
            </li>
          </ul>
        </li>
        <li>
          Still not working?? Feel free to reach out to
          <a href="https://twitter.com/psychothan">@psychothan</a> or chime in
          on the <a href="https://discord.gg/kA8vFDUkr5">Discord server</a> 🤗
        </li>
      </ol>
    </div>
  </div>
</template>

<style scoped>
div.flex {
  background: white;
  display: flex;
}

p {
  margin: 0;
}

progress {
  -webkit-appearance: none;
  width: 100%;
}

code {
  padding: 0 0.5em;
  font-family: "Source Code Pro", monospace;
  font-size: 0.8em;
  background-color: rgb(245, 245, 245);
}

/* Firefox */
progress.low::-moz-progress-bar {
  background: #26ab79;
}

progress.med::-moz-progress-bar {
  background: #f98429;
}

progress.high::-moz-progress-bar {
  background: #ec2147;
}

/* Safari and Chrome */
progress.low::-webkit-progress-bar {
  background: #d8f6eb;
}

progress.low::-webkit-progress-value {
  background: #26ab79;
}

progress.med::-webkit-progress-bar {
  background: #fef0e4;
}

progress.med::-webkit-progress-value {
  background: #f98429;
}

progress.high::-webkit-progress-bar {
  background: #fde6ea;
}

progress.high::-webkit-progress-value {
  background: #ec2147;
}
</style>

<script>
import { create as createClient } from "ipfs-http-client";

export default {
  name: "IPFS Client",
  emits: ["online", "ipfs"],
  props: ["objkts"],
  data() {
    return {
      agentVersion: undefined,
      version: undefined,
      pins: undefined,
      peers: undefined,
      status: "Connecting to IPFS...",
      online: false,
      ipfs: undefined,
      stats: {},
      size: undefined,
      max: undefined,
    };
  },
  computed: {
    progressClass() {
      const percentage = this.size / this.max;
      return percentage > 0.3 ? (percentage > 0.7 ? "high" : "med") : "low";
    },
  },
  created() {
    this.getIpfsNodeInfo();
    this.timerID = setInterval(this.getIpfsNodeInfo, 1000);
  },

  methods: {
    async getIpfsNodeInfo() {
      // check for ipfs node instance.
      this.ipfs = this.ipfs || createClient("/ip4/127.0.0.1/tcp/5001");
      this.$emit("ipfs", this.ipfs);

      try {
        await this.ipfs.id();

        this.online = true;
        this.$emit("online", true);
        const { agentVersion, id } = await this.ipfs.id();
        const peers = await this.ipfs.swarm.peers();
        const stats = await this.ipfs.repo.stat();

        this.agentVersion = agentVersion;
        this.id = id;
        this.peers = peers;
        this.stats = stats;
        this.size = (Number(stats.repoSize) / 1e9).toFixed(2);
        this.max = (Number(stats.storageMax) / 1e9).toFixed(2);
      } catch (err) {
        if (err.name == "TypeError") {
          this.online = false;
          this.$emit("online", false);
        } else {
          this.$emit("online", false);
        }
      }
    },
  },
};
</script>
