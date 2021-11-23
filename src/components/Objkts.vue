<template>
  <table
    v-if="Object.keys(objkts).length > 0"
    style="width: 1440px; margin: auto auto"
  >
    <thead>
      <tr>
        <th>Title</th>
        <th>Artist</th>
        <th>Medium</th>
        <th>Description</th>
        <th>Metadata</th>
        <th>Unpin</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="objkt in curPage" :key="objkt.pk_id.toString()">
        <td style="font-style: italic">
          <a
            :href="`https://dweb.link/ipfs/${
              objkt.artifact_uri.split('//')[1]
            }`"
            >{{ objkt.title || "Untitled" }}</a
          >
        </td>
        <td>
          <a v-if="objktLink(objkt)" :href="objktLink(objkt)">{{
            objktAlias(objkt)
          }}</a>
          <span v-else>{{ objktAlias(objkt) }}</span>
        </td>
        <td>{{ objkt?.mime }}</td>
        <td>{{ objkt?.description }}</td>
        <td>
          <a :href="objkt.metadata">{{
            objkt.metadata.slice(7, 15) + "..."
          }}</a>
        </td>
        <td style="text-align: center">
          <span @click="unpin(objkt.pk_id)" class="unpin">❌</span>
        </td>
      </tr>
    </tbody>
  </table>
  <div class="section" v-if-else="online">
    <h2>You are all set to start pinning 👍</h2>
    <hr style="margin: 3em 0" />
    <ol>
      <li>
        Enter any valid Tezos wallet address into the search bar above. This
        fetches the NFT metadata from
        <a href="https://data.objkt.com/docs/">data.objkt.com</a>.
      </li>
      <li>
        The metadata fetching is pretty fast but depending on the size of a
        collection, the actual
        <a href="https://docs.ipfs.io/how-to/pin-files/">pinning</a>
        could take some time to complete. The intermediate state is preserved so
        if you refresh/close the tab it will pickup where it left off.
      </li>
      <li>
        Everything is local to your web browser, no data/info is sent to any
        servers (except the initial query to
        <a href="https://data.objkt.com/docs/">data.objkt.com</a>).
      </li>
      <li>
        Occassionally there might be timeouts when pinning large/slow files...
        you can restart the process by re-submitting the search.
      </li>
      <li>
        <p>
          You will continue to host the files for as long as your
          <span class="highlight">IPFS node</span> is online (you can close this
          tab once the pinning is complete).
        </p>
      </li>
      <li>
        Feel free to reach out to
        <a href="https://twitter.com/psychothan">@psychothan</a> or chime in on
        the <a href="https://discord.gg/kA8vFDUkr5">Discord server</a> if you
        have any ❓❓❓
      </li>
    </ol>
  </div>
  <div class="pagination">
    <div
      v-for="num in numPages"
      :key="num?.at(1)"
      @click="goToPage(num?.at(1))"
      :class="{ current: page === num?.at(1) }"
    >
      {{ num?.at(0) }}
    </div>
  </div>
</template>

<style scoped>
table {
  font-family: "Jost", sans-serif;
  border-collapse: collapse;
}

td,
th {
  border: 1px solid #0b3a53;
  padding: 0.5rem;
  text-align: left;
}

tbody tr:nth-child(odd) {
  background-color: rgb(250, 250, 250);
}

.unpin {
  cursor: pointer;
}

div.pagination {
  margin: 2em 1em;
  display: flex;
  justify-content: center;
}

div.pagination div {
  padding: 0 1em;
  cursor: pointer;
  margin: 0.1em;
  border: 1px solid #0b3a53;
}

div.pagination div:hover {
  background-color: #e6f2fd;
}

.current {
  background-color: #fde6ea;
}
</style>

<script>
import { get, del } from "idb-keyval";

export default {
  name: "Objkts",
  props: ["objkts", "ipfs"],
  emits: ["unpin"],
  data() {
    return {
      page: 0,
      perPage: 10,
    };
  },
  mounted() {
    this.goToPage(0);
  },
  computed: {
    numPages() {
      let pages = [];
      const numPages = Math.ceil(
        Object.keys(this.objkts).length / this.perPage
      );

      if (numPages === 0) {
        return [];
      }

      for (let i = 0; i < numPages; i++) {
        pages.push([(i + 1).toString(), i]);
      }

      const first = pages.shift();
      const last = pages.length === 0 ? [] : [pages.pop()];

      if (pages.length > 7) {
        // do we need to truncate?
        if (this.page < 3) {
          //we are at the beginning
          pages = [...pages.slice(0, 3), ["...", 4]];
        } else if (this.page > numPages - 4) {
          //we are at the end
          pages = [["...", numPages - 5], ...pages.slice(numPages - 5)];
        } else {
          // we are in the middle pages
          pages = [
            ["...", this.page - 2],
            ...pages.slice(
              Math.max(this.page - 2, 0),
              Math.min(this.page + 2, pages.length)
            ),
            ["...", this.page + 3],
          ];
        }
      }

      return [first, ...pages, ...last];
    },
    curPage() {
      const start = this.perPage * this.page;
      return Object.values(this.objkts).slice(start, start + this.perPage);
    },
  },
  methods: {
    goToPage(num) {
      this.page = num;
    },
    objktLink(objkt) {
      if (objkt?.creator?.twitter) {
        return `https://twitter.com/${objkt.creator.twitter}`;
      } else if (objkt?.creator?.site) {
        return objkt.creator.site;
      } else if (objkt?.creator?.address) {
        return `https://tzkt.io/${objkt.creator.address}`;
      } else {
        return undefined;
      }
    },
    objktAlias(objkt) {
      if (!objkt.creator) {
        return objkt.fa2?.name;
      }

      if (objkt.creator.alias) {
        return objkt.creator.alias;
      } else {
        const addr = objkt.creator.address;
        return addr.substring(0, 5) + "..." + addr.substring(addr.length - 5);
      }
    },
    async unpin(id) {
      const ipfsAssets = ["artifact_uri", "metadata"];

      const objkt = await get(id);

      const cids = [];
      console.log(`Unpinning objkt ${objkt.pk_id}`);

      for (let uri of ipfsAssets) {
        if (objkt[uri]) {
          const cid = objkt[uri].match(/^ipfs:\/\/(\S+)$/);
          if (cid) {
            cids.push(cid[1]);
          }
        }
      }

      for await (let c of this.ipfs.pin.rmAll(cids)) {
        console.log(`Removed CID: ${c}`);
      }

      await del(id);
      this.$emit("unpin", id);
    },
  },
};
</script>
