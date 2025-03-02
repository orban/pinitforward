<template>
  <table v-if="curPage.length > 0" style="width: 1440px; margin: auto auto">
    <thead>
      <tr>
        <th>Objkt</th>
        <th>Title</th>
        <th>Creator</th>
        <th>Medium</th>
        <th>Description</th>
        <th>Metadata</th>
        <th>Unpin</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="objkt in curPage" :key="objkt?.pk_id?.toString()">
        <td>
          <a v-if="objktLink(objkt)" :href="objktLink(objkt)">{{
            objkt.id.length > 6
              ? objkt.id.substring(0, 3) + "..." + objkt.id.slice(-3)
              : objkt.id
          }}</a>
          <span v-else>{{
            objkt.id.substring(0, 3) + "..." + objkt.id.slice(-3)
          }}</span>
        </td>
        <td style="font-style: italic">
          <a
            :href="`https://dweb.link/ipfs/${
              objkt.artifact_uri.split('//')[1]
            }`"
            >{{ objkt.title || "Untitled" }}</a
          >
        </td>
        <td>
          <a v-if="creatorLink(objkt)" :href="creatorLink(objkt)">{{
            creatorAlias(objkt)
          }}</a>
          <span v-else>{{ objktAlias(objkt) }}</span>
        </td>
        <td>{{ objkt?.mime }}</td>
        <td>{{ objkt?.description }}</td>
        <td>
          <a :href="objkt.metadata">{{
            objkt.metadata !== "" ? objkt.metadata.slice(7, 15) + "..." : ""
          }}</a>
        </td>
        <td style="text-align: center">
          <span @click="unpin(objkt.pk_id)" class="unpin">❌</span>
        </td>
      </tr>
    </tbody>
  </table>
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
    creatorLink(objkt) {
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
    creatorAlias(objkt) {
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
    objktLink(objkt) {
      if (objkt?.fa2?.name === "hic et nunc") {
        return `https://hicetnunc.art/objkt/${objkt.id}`;
      } else if (objkt?.fa2?.path) {
        return `https://objkt.com/asset/${objkt.fa2.path}/${objkt.id}`;
      } else {
        return undefined;
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
