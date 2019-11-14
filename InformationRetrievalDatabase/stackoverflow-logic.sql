--D1
-- search based on keywords and return question ids
DROP FUNCTION if exists simpleSearchKeyword(userid int, S text);
CREATE OR REPLACE FUNCTION simpleSearchKeyword(userid int, S text) 
returns int[] as $$
declare questionIdsArray int[] DEFAULT '{}';
declare t_row record; 
declare storeSearchVar text;
begin
 for t_row in SELECT questionid FROM q_view 	WHERE
	title ~* S or body ~* S loop
	questionIdsArray := questionIdsArray || t_row.questionid;
 end loop;
​
select storeSearch(userid, S) into storeSearchVar;
return questionIdsArray;
end;
$$
LANGUAGE plpgsql;
-- select simpleSearchKeyword(2, 'keyword');
​
​
-- storing searches initiated by user
drop function if exists storeSearch(userid int, querytext text);
create  or replace function storeSearch(userid int, querytext text)
	returns text as $$ 
	declare storedsearch text; 
	begin
		INSERT INTO search_history (searchdate, userid, querytext)
		VALUES (NOW(), userid, querytext);
		storedsearch =  NOW() || ',' || userid || ',' || querytext;
		return storedsearch;
	end;
	$$
language plpgsql;
-- select storeSearch(1, 'keyword')
​
-- add a marking
drop function if exists addMarking(userid int, questionid int)
create  or replace function addMarking(userid int, questionid int)
	returns void as $$ 
	begin
		INSERT INTO markings (userid, questionid)
		VALUES (userid, questionid);
	end;
	$$
language plpgsql;
select addMarking(1, 1)
​
-- add an annotation
drop function if exists addAnnotation(markingid int, body text)
create or replace function addAnnotation(markingid int, body text)
	returns int as $$ 
	declare
	newAnnotationId int;
	begin
		INSERT INTO annotations (markingid, body)
		VALUES (markingid, body) returning annotationid into newAnnotationId;
		return newAnnotationId;
	end;
	$$
language plpgsql;
select addAnnotation(2, 'hello there')
​
-- D2 
--/ We established a new inverted index from the post table where we insert all distinct 
--  words to lowercase from ‘title’ & ‘posts’ into the stack_wi table. Only a word and reference to that id is stored as an inverted index.
drop table if exists stack_wi;
create table stack_wi as
select id, tablename, lower(word) word from words
where word ~* '^[a-z][a-z0-9_]+$'
and tablename = 'posts' and (what='title' or what='body')
group by id,word,tablename;
​
drop index if exists stack_w_index;
create index stack_w_index on words(word);
​
drop index if exists stack_id_index;
create index stack_id_index on words(word);
​
​
--D3 
drop function if exists exactMatch(VARIADIC w text[]);
create or replace function exactMatch(VARIADIC w text[])
returns table(questionid integer, title text, body text) as $$
declare
	w_elem text;
	t text := 'select questionid, title, body from q_view q, ';
	idx integer default 0;
	w_length int := array_length(w, 1);
begin
	foreach w_elem in array w
	loop
	idx := idx + 1;
	if idx = 1 then
		t := t || '(SELECT id FROM words WHERE word= ''' || w_elem || ''' ';
	end if;
	
	if idx > 1 and idx < w_length then
		t := t || 'intersect SELECT id FROM words WHERE word= ''' || w_elem || ''' ';
	end if;	
	
	if idx = w_length then
		t := t || 'intersect SELECT id FROM words WHERE word= ''' || w_elem || ''') t where q.questionid = t.id ';
	end if;
		
	end loop;
	return query execute t;
end $$
language 'plpgsql';
​
-- select * from exactMatch('missing', 'something', 'here', 'admit')
-- select * from exactMatch('here');
​
--D4
drop function if exists best_match(VARIADIC w text[]);
create or replace function best_match(VARIADIC w text[])
returns table(questionid integer, rank bigint, body text) as $$
declare
	w_elem text;
	t text := 'SELECT q.questionid, sum(relevance) rank, body FROM q_view q, ';
	idx integer default 0;
	w_length int := array_length(w, 1);
begin
	foreach w_elem in array w
	loop
	idx := idx + 1;
	if idx = 1 then
		t := t || '(SELECT distinct id, 1 relevance FROM words WHERE word = ''' || w_elem || ''' ';
	end if;
	
	if idx > 1 and idx < w_length then
		t := t || 'UNION ALL SELECT distinct id, 1 relevance FROM words WHERE word = ''' || w_elem || ''' ';
	end if;	
	
	if idx = w_length then
		t := t || 'UNION ALL SELECT distinct id, 1 relevance FROM words WHERE word = ''' || w_elem || ''') t WHERE q.questionid=t.id GROUP BY q.questionid, body ORDER BY rank DESC; ';
	end if;
		
	end loop;
	return query execute t;
end $$
language 'plpgsql';
​
-- select * from best_match('of', 'and')
​
--D5
DROP TABLE IF EXISTS weighted_wi;
CREATE TABLE weighted_wi(
id int, word text, document_term_count int, occurrences_of_term_in_document int, documents_containing_term int, tf numeric, idf numeric, tfidf numeric);
​
drop index if exists index_weighted;
create index index_weighted on weighted_wi(word);
drop index if exists index_weighted_id;
create index index_weighted_id on weighted_wi(id);
​
insert into weighted_wi (id, word, document_term_count, occurrences_of_term_in_document, documents_containing_term)
select stack_wi.id, stack_wi.word, t. document_term_count, t2.occurrences_of_term_in_document, t3.documents_containing_term from stack_wi,
(select id, count(*) document_term_count from stack_wi group by id) as t,
(select id, word, count(*) occurrences_of_term_in_document from stack_wi group by id, word) as t2,
(select word, count(*) documents_containing_term from words group by word) as t3
where stack_wi.id = t2.id and stack_wi.word = t2.word and stack_wi.id = t.id and stack_wi.word = t3.word;
​
​
drop function if exists relevanceOfDocumentToTerm();
create or replace function relevanceOfDocumentToTerm(questionid integer, term text)
returns numeric as $$
declare
	termFrequency numeric;
	inverseDocumentFrequency numeric;
	relevanceOfDocToTerm numeric;
	record record;
begin
for record in select distinct * from weighted_wi where id = questionid and word = term loop
​
	 termFrequency = log(1::numeric + (record.document_term_count::numeric / record.occurrences_of_term_in_document::numeric));
	 inverseDocumentFrequency = 1 / record.documents_containing_term::numeric;
	 relevanceOfDocToTerm = termFrequency * inverseDocumentFrequency;
end loop; 
​
	return relevanceOfDocToTerm;
end; $$
language 'plpgsql';
​
-- select * from relevanceOfDocumentToTerm(19, 'acos');
​
drop function if exists insertRelevance();
create or replace function insertRelevance()
returns void as $$
declare
	termFrequency numeric;
	inverseDocumentFrequency numeric;
	relevanceOfDocToTerm numeric;
	record record;
begin
for record in select * from weighted_wi loop
	 termFrequency = log(1::numeric + (record.document_term_count::numeric / record.occurrences_of_term_in_document::numeric));
	 inverseDocumentFrequency = 1 / record.documents_containing_term::numeric;
	 relevanceOfDocToTerm = termFrequency * inverseDocumentFrequency;
  update weighted_wi set tfidf=relevanceOfDocToTerm where id = record.id and word = record.word;
end loop; 
end; $$
language 'plpgsql';
​
-- select * from insertRelevance();
​
​
--D6
drop function if exists best_match_with_weight(VARIADIC w text[]);
create or replace function best_match_with_weight(VARIADIC w text[])
returns table(questionid integer, tfidf numeric, body text) as $$
declare
	w_elem text;
	t text := 'SELECT q.questionid, sum(tfidf) rank, body FROM q_view q, ';
	idx integer default 0;
	w_length int := array_length(w, 1);
begin
	foreach w_elem in array w
	loop
	idx := idx + 1;
	if idx = 1 then
		t := t || '(SELECT distinct id, tfidf FROM weighted_wi WHERE word = ''' || w_elem || ''' ';
	end if;
	
	if idx > 1 and idx < w_length then
		t := t || 'UNION ALL SELECT distinct id, tfidf FROM weighted_wi WHERE word = ''' || w_elem || ''' ';
	end if;	
	
	if idx = w_length then
		t := t || 'UNION ALL SELECT distinct id, tfidf FROM weighted_wi WHERE word = ''' || w_elem || ''') t WHERE q.questionid=t.id GROUP BY q.questionid, body ORDER BY rank DESC; ';
	end if;
		
	end loop;
	return query execute t;
end $$
language 'plpgsql';
​
-- select * from best_match_with_weight('process', 'stopped');
