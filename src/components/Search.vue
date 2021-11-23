<template>
  <header>
    <nav class="bar">
      <div class="container">
        <form class="search" @submit.prevent="findObjkts">
          <input
            v-model="address"
            placeholder="Enter Tezos wallet address to pin assets (both creations and collection)"
            class="text"
          />
          <input type="submit" value="📍" />
        </form>
        <div id="status">IPFS {{ online ? "🟢" : "🔴" }}</div>
      </div>
    </nav>
  </header>
</template>

<style scoped>
nav.bar {
  display: flex;
  justify-content: center;
  width: 100%;
  background: rgb(240, 246, 250);
  border-bottom: 1px solid #0b3a53;
}

nav.bar > * {
  margin: 0 0.5em;
}

nav .search {
  display: flex;
  flex: 1;
  margin: 0 1em;
  border: 1px solid #0b3a53;
}

nav .search input.text {
  width: 100%;
  padding: 0 1em 0 1em;
  color: #5694f1;
  font-size: 1.2em;
  font-weight: bold;
}

nav .search input[type="submit"] {
  cursor: pointer;
  font-size: 1.2em;
  padding: 0 0.5em;
  background-color: #fde6ea;
  border-left: 1px solid #0b3a53;
}

nav .search input {
  border: none;
}

div#status {
  height: 42px;
  line-height: 42px;
  padding: 0 0.5em;
}
</style>

<script>
import { accountQuery, graphqlQuery } from "../helpers/queries";
import { get } from "idb-keyval";

export default {
  name: "Nav",
  props: ["online"],
  emits: ["results", "progress"],
  data() {
    return { address: "" };
  },
  methods: {
    async findObjkts() {
      this.$emit("progress", true);
      if (navigator.storage && navigator.storage.persist) {
        const isPersisted = await navigator.storage.persist();
        console.log(`Persisted storage granted: ${isPersisted}`);
      }

      const query = await this.fetchObjkts(this.address);

      const newObjkts = [];

      for (const objkt of query) {
        const o = await get(objkt.pk_id);
        if (!o) {
          newObjkts.push(objkt);
        }
      }

      if (newObjkts.length === 0) {
        this.$emit("results", []);
        alert(
          "Search returned no new results... all NFTs are currently pinned."
        );
      } else {
        this.$emit("results", newObjkts);
      }
    },
    async fetchObjkts(address) {
      let query;
      let operation;
      let offset = 0;

      if (address.startsWith("tz")) {
        query = accountQuery;
        operation = "getCollection";
      } else {
        alert("Not a valid Tezos address");
        throw "Not a valid Tezos address";
      }
      let objkts = [];
      let res;
      do {
        res = await graphqlQuery(
          query,
          { address: address, offset: offset },
          operation
        );
        if (res.errors) {
          console.error(res.errors);
        }
        objkts = [...objkts, ...res?.data?.token];
        offset += 250;
      } while (res?.data?.token?.length === 250);
      return objkts;
    },
  },
};
</script>
