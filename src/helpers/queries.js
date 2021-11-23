const fields = `
{
    artifact_uri
    creator {
      address
      alias
      description
      site
      tzdomain
      twitter
    }
    description
    display_uri
    fa2 {
      name
      contract
    }
    id
    mime
    metadata
    pk_id
    thumbnail_uri
    timestamp
    title
  }
`;

const accountQuery = `
query getCollection($address: String!, $offset: Int!) {
  token(offset: $offset, order_by: {pk_id: asc}, where: {_or: [{creator: {address: {_eq: $address}}}, {token_holders: {holder: {address: {_eq: $address}}}}]}) 
  ${fields}
}
`;

const objktQuery = `
query getObjkt($address: String!, $offset: Int!) {
    token(where: {id: {_eq: $address}}) 
    ${fields}
}
`;

async function graphqlQuery(query, variables, operationName) {
  const result = await fetch("https://data.objkt.com/v1/graphql", {
    method: "POST",
    body: JSON.stringify({
      query: query,
      variables: variables,
      operationName: operationName,
    }),
  });

  return await result.json();
}

export { accountQuery, objktQuery, graphqlQuery };
